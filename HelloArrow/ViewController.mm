//
//  ViewController.m
//  HelloArrow
//
//  Created by fminor on 2/27/15.
//  Copyright (c) 2015 ___FULLUSERNAME___. All rights reserved.
//

#import "ViewController.h"
#import "GLView.h"

@interface ViewController ()
{
    GLView                      *_glView;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _glView = [[GLView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_glView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
