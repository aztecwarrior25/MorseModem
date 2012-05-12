//
//  MessageSend.h
//  MyAVController
//
//  Created by Shriniwas Kulkarni on 3/28/11.
//  Copyright 2011 ASU. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Torch.h"

@interface MessageSend : UIViewController  <UITextFieldDelegate> {
	IBOutlet UITextField *message;
	IBOutlet UILabel *msgText;
	IBOutlet UIButton *startButton;
	NSMutableArray *morseLookupTable;
	Torch* torch;
}


@property (nonatomic, retain) UITextField *message;
@property (nonatomic, retain) UIButton *startButton;
@property (nonatomic, retain) UILabel *msgText;
@property (nonatomic, retain) NSMutableArray *morseLookupTable;

- (IBAction) startMorseStrobe;
- (IBAction) stopMorseStrobe;
- (IBAction) backToMain;


@end
