//
//  SGPlaceDetailsViewController.m
//  SpotAndGo
//
//  Created by Truman, Christopher on 9/1/12.
//
//

#import "SGPlaceDetailsViewController.h"
#import "SGPlace.h"
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import <AddressBook/AddressBook.h>
#include <QuartzCore/QuartzCore.h>

@interface SGPlaceDetailsViewController ()

@end

@implementation SGPlaceDetailsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

+(SGPlaceDetailsViewController*)placeDetailsViewControllerWithPlace:(SGPlace*)place{
    SGPlaceDetailsViewController * placeDetailsViewController = [[SGPlaceDetailsViewController alloc] init];

    placeDetailsViewController.place = place;
    [[placeDetailsViewController view] setFrame:CGRectMake(0, 0, 155, 95)];
    [placeDetailsViewController.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"gplaypattern.png"]]];
    
    UIFont * font = [UIFont fontWithName:@"Futura-Medium" size:18];

    if (![place.phone_number isKindOfClass:[NSNull class]] && ![place.phone_number isEqualToString:@""]) {
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:placeDetailsViewController action:@selector(handleTap)];
        tap.delegate = placeDetailsViewController;
        [placeDetailsViewController.view addGestureRecognizer:tap];
        
        placeDetailsViewController.phoneLabel = [[NIAttributedLabel alloc] initWithFrame:CGRectMake (0, 10, 150, 30)];
        placeDetailsViewController.phoneLabel.delegate = placeDetailsViewController;
        [placeDetailsViewController.phoneLabel setTextAlignment:NSTextAlignmentCenter];
        [placeDetailsViewController.phoneLabel setBackgroundColor:[UIColor clearColor]];
        [placeDetailsViewController.phoneLabel setText:place.phone_number];
        [placeDetailsViewController.phoneLabel setFont:font];
        [placeDetailsViewController.phoneLabel setAutoDetectLinks:YES];
        [placeDetailsViewController.phoneLabel setDataDetectorTypes:NSTextCheckingTypePhoneNumber];
        [placeDetailsViewController.phoneLabel setLinksHaveUnderlines:YES];
        [placeDetailsViewController.view addSubview:placeDetailsViewController.phoneLabel];
    }
    
    UIButton * directionsButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [directionsButton setFrame:CGRectMake(10, 55, 135, 30)];
    [directionsButton.titleLabel setFont:font];
    directionsButton.backgroundColor = [UIColor clearColor];
    directionsButton.alpha = 0.8;
    directionsButton.layer.borderColor = [UIColor blackColor].CGColor;
    directionsButton.layer.borderWidth = 2;
    directionsButton.layer.cornerRadius = 10;
    [directionsButton setTitle:@"Directions" forState:UIControlStateNormal];
    [directionsButton addTarget:placeDetailsViewController action:@selector(getDirections) forControlEvents:UIControlEventTouchDown];
    [placeDetailsViewController.view addSubview:directionsButton];
    
//    placeDetailsViewController.nameLabel = [[UILabel alloc] initWithFrame:CGRectMake (0, 115/2, 150, 40)];
//    [placeDetailsViewController.nameLabel setTextAlignment:NSTextAlignmentCenter];
//    placeDetailsViewController.nameLabel.backgroundColor = [UIColor clearColor];
//    [placeDetailsViewController.nameLabel setFont:font];
//    [placeDetailsViewController.nameLabel setTextColor:[UIColor blackColor]];
//    placeDetailsViewController.nameLabel.text = place.name;
//    [placeDetailsViewController.nameLabel setLineBreakMode:UILineBreakModeWordWrap];
//    [placeDetailsViewController.nameLabel setNumberOfLines:2];
//    [placeDetailsViewController.view addSubview:placeDetailsViewController.nameLabel];

    return placeDetailsViewController;
}

-(void)handleTap{
    NSString * cleanedPhoneString = [[[self.phoneLabel.text stringByReplacingOccurrencesOfString:@"(" withString:@""] stringByReplacingOccurrencesOfString:@")" withString:@""]stringByReplacingOccurrencesOfString:@" " withString:@"-"];
    NSString * telephoneSchemeString = [NSString stringWithFormat:@"tel:1-%@", cleanedPhoneString];
    NSLog(@"%@", telephoneSchemeString);
    NSURL * phoneURL = [NSURL URLWithString:telephoneSchemeString];
    if ([[UIApplication sharedApplication] canOpenURL:phoneURL]) {
        [[GANTracker sharedTracker] trackEvent:@"phone_call"
                                        action:@"launch_phone"
                                         label:self.place.phone_number
                                         value:0
                                     withError:nil];
        [[UIApplication sharedApplication] openURL:phoneURL];
    }else{
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Oops" message:@"Your device can't make phone calls" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil];
        [alert show];
    }
}

-(void)getDirections{
    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake([self.place.latitude doubleValue], [self.place.longitude doubleValue]);
    NSString * mapsURLFormatted = [NSString stringWithFormat:@"http://maps.google.com/maps?saddr=%f,%f&daddr=%@",coord.latitude, coord.longitude, self.place.street];
    if ([NSClassFromString(@"MKMapItem") instancesRespondToSelector:@selector(isCurrentLocation)]){
        NSDictionary * addressDictionary = [NSDictionary dictionaryWithObjectsAndKeys:self.place.street, kABPersonAddressStreetKey,
                                            self.place.city,kABPersonAddressCityKey,
                                            self.place.state,kABPersonAddressStateKey,
                                            self.place.postal_code,kABPersonAddressZIPKey, nil];
        MKPlacemark * placemark = [[MKPlacemark alloc] initWithCoordinate:coord addressDictionary:addressDictionary];
        MKMapItem * mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
        [mapItem setName:self.place.name];
        [mapItem setPhoneNumber:self.place.phone_number];
        if (![self.place.website isKindOfClass:[NSNull class]]) {
            [mapItem setUrl:[NSURL URLWithString:self.place.website]];
        }
        [MKMapItem openMapsWithItems:@[ mapItem ] launchOptions:nil];
        [[GANTracker sharedTracker] trackEvent:@"get_directions"
                                        action:@"launch_apple_maps"
                                         label:self.place.street
                                         value:0
                                     withError:nil];
    }else{
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:mapsURLFormatted]];
        [[GANTracker sharedTracker] trackEvent:@"get_directions"
                                        action:@"launch_google_maps"
                                         label:self.place.street
                                         value:0
                                     withError:nil];
    }
}

- (void)attributedLabel:(NIAttributedLabel *)attributedLabel didSelectTextCheckingResult:(NSTextCheckingResult *)result atPoint:(CGPoint)point{
    
}

- (BOOL)attributedLabel:(NIAttributedLabel *)attributedLabel shouldPresentActionSheet:(UIActionSheet *)actionSheet withTextCheckingResult:(NSTextCheckingResult *)result atPoint:(CGPoint)point{
    return YES;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer{
    return YES;
}

// called when the recognition of one of gestureRecognizer or otherGestureRecognizer would be blocked by the other
// return YES to allow both to recognize simultaneously. the default implementation returns NO (by default no two gestures can be recognized simultaneously)
//
// note: returning YES is guaranteed to allow simultaneous recognition. returning NO is not guaranteed to prevent simultaneous recognition, as the other gesture's delegate may return YES
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    return NO;
}

// called before touchesBegan:withEvent: is called on the gesture recognizer for a new touch. return NO to prevent the gesture recognizer from seeing this touch
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ((touch.view == self.phoneLabel)) {//change it to your condition
        return YES;
    }
    return NO;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
