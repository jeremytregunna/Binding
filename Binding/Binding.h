//
//  Binding.h
//  Binding
//
//  Created by Jeremy Tregunna on 1/27/2014.
//  Copyright (c) 2014 Jeremy Tregunna. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^BindingFunction)(id value);

@interface Binding : NSObject

+ (instancetype)bindTarget:(id)target selector:(SEL)selector;
+ (instancetype)bindTarget:(id)target keyPath:(NSString*)keyPath;

// Operations

- (instancetype)next:(BindingFunction)fn;
- (void)complete;

@end
