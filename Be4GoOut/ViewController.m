//
//  ViewController.m
//  Be4GoOut
//
//  Created by Mark Zhong on 7/31/16.
//  Copyright © 2016 Mark Zhong. All rights reserved.
//

#import "ViewController.h"
#import "Forecastr.h"

@interface ViewController (){
    Forecastr *forecastr;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    
    self.locationManager = [[CLLocationManager alloc]init];
    self.locationManager.delegate = self;
    [self.locationManager requestWhenInUseAuthorization];
    [self.locationManager requestLocation];
    [self updateTime];
    
    
    
    [NSTimer scheduledTimerWithTimeInterval:60*15 target:self
                                   selector:@selector(zoomCurrent) userInfo:nil repeats:YES];
    
    [NSTimer scheduledTimerWithTimeInterval:60*5 target:self
                                   selector:@selector(updateWeather) userInfo:nil repeats:YES];
    
    
    [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateTime) userInfo:nil repeats:YES];
    self.myMap.showsScale = YES;

    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(addLongpressGesture:)];
    [self.myMap addGestureRecognizer:longPress];
    
    [self getWeather:self.locationManager.location];

}

-(void)addLongpressGesture:(UILongPressGestureRecognizer *)gestureRecognizer
{
    
    NSLog(@"Long Pressed");
    [self setNeedsFocusUpdate];    
    
    
}

- (UIView *)preferredFocusedView
{
    
    return _tabView;

}


- (IBAction)standardButton:(id)sender {
    self.myMap.mapType = MKMapTypeStandard;
}

- (IBAction)sateliteButton:(id)sender {
    self.myMap.mapType = MKMapTypeSatellite;


}
- (IBAction)hybridButton:(id)sender {
    self.myMap.mapType = MKMapTypeHybridFlyover;

    if ([_myMap respondsToSelector:@selector(camera)]) {
        [_myMap setShowsBuildings:YES];
        MKMapCamera *newCamera = [[_myMap camera] copy];
        [newCamera setPitch:45.0];
        [newCamera setHeading:270.0];
        [newCamera setAltitude:500.0];
        [_myMap setCamera:newCamera animated:YES];
     
    }
     
}

- (IBAction)findMe:(id)sender {
    
    [self zoomCurrent];
}
- (IBAction)trafficControl:(id)sender {
    
    if(self.myMap.showsTraffic==true){
        self.myMap.showsTraffic = false;
        NSLog(@"turn off: %d", self.myMap.showsTraffic);
    }else{
        self.myMap.showsTraffic = true;
        NSLog(@"turn on: %d", self.myMap.showsTraffic);


    }
    
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"locationManager didFailWithError %@", error);
}
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    NSLog(@"locationManager didUpdateLocations");
    
    NSLog(@"location info object=%@", [locations lastObject]);
    CLLocation *location1 = [locations lastObject];

    
    MKCoordinateRegion region;
    region.center = location1.coordinate;
    region.span.longitudeDelta = 0.0001;
    region.span.latitudeDelta = 0.2;
    
    MKCoordinateRegion fitRegion = [self.myMap regionThatFits:region];
    self.myMap.showsTraffic = true;
    [self.myMap setRegion:fitRegion animated:YES];
    
    [self updateLocationInfo:location1];
    [self zoomCurrent];
    
    NSLog(@"location is %f, %f", location1.coordinate.latitude, location1.coordinate.longitude );
    
    [self getWeather:location1];
}


-(void)zoomCurrent{
    NSLog(@"zoomCurrent called");
    //[self updateLocationInfo];
    
    MKCoordinateRegion region;
    region.center = self.locationManager.location.coordinate;
    region.span.longitudeDelta = 0.0001;
    region.span.latitudeDelta = 0.2;
    
    MKCoordinateRegion fitRegion = [self.myMap regionThatFits:region];

    
    self.myMap.showsTraffic=true;

    [self.myMap setNeedsLayout];
    [self.myMap setRegion:fitRegion animated:YES];
    

}

-(void)updateWeather{
    [self getWeather:self.locationManager.location];

}
-(void)getWeather:(CLLocation*)locationPar{
    
    forecastr = [Forecastr sharedManager];
    forecastr.apiKey = @"YOUR_API_KEY"; // You will need to set the API key here (only set it once in the entire app)
    
    [forecastr getForecastForLatitude:locationPar.coordinate.latitude longitude:locationPar.coordinate.longitude time:nil exclusions:nil extend:nil language:nil success:^(NSMutableDictionary *JSON) {
        //NSLog(@"JSON Response was: %@", JSON);
        
        NSArray *currently = [JSON objectForKey:@"currently"];
        
        float a = [[currently valueForKey:@"apparentTemperature"] doubleValue];
        int b = round(a);
        NSLog(@"a is %f", a);
        NSLog(@"b is %d", b);
        
        // NSLog(@"current is: %lf", (long)[[currently valueForKey:@"apparentTemperature"] doubleValue]);
        
        
        NSLog(@"current summary is: %@", [currently valueForKey:@"summary"]  );
        
        self.tempLabel.text = [NSString stringWithFormat:@"%d°", b];
        self.weatherSummr.text = [currently valueForKey:@"summary"];
        
        
    } failure:^(NSError *error, id response) {
        NSLog(@"Error while retrieving forecast: %@", [forecastr messageForError:error withResponse:response]);
    }];

    
    
}

-(void)updateLocationInfo:(CLLocation*)location{
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];

    
    [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
        if (error == nil && [placemarks count] > 0) {
            CLPlacemark *placemark = [placemarks lastObject];
            
            NSString *cityName = placemark.locality;
            
            NSLog(@"city name is: %@", placemark.locality);
            /*
            _addressLabel.text = [NSString stringWithFormat:@"%@ %@\n%@, %@, %@\n%@",
                                  placemark.subThoroughfare, placemark.thoroughfare,
                                  placemark.locality,
                                  placemark.administrativeArea,placemark.postalCode,
                                  placemark.country];
             */
            self.cityName.text = cityName;
            
        } else {

            NSLog(@"%@", error.debugDescription);
        }
    } ];
}

-(void)updateTime{
    /*
    NSDateFormatter *dateFormatter=[[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    // or @"yyyy-MM-dd hh:mm:ss a" if you prefer the time with AM/PM
    NSLog(@"%@",[dateFormatter stringFromDate:[NSDate date]]);*/
    
    // get current date/time
    NSDate *today = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    // display in 12HR/24HR (i.e. 11:25PM or 23:25) format according to User Settings
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    NSString *currentTime = [dateFormatter stringFromDate:today];
    //NSLog(@"User's current time :%@",currentTime);
    
    self.localTime.text = currentTime;
    
    
    NSDateFormatter *dateFormatter2 = [[NSDateFormatter alloc] init];
    [dateFormatter2 setDateFormat:@"MM/dd/YYYY"];
    //NSLog(@"%@", [dateFormatter2 stringFromDate:[NSDate date]]);
    
    self.dayLabel.text = [dateFormatter2 stringFromDate:[NSDate date]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
