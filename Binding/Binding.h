//
//  Binding.h
//  Binding
//
//  Created by Jeremy Tregunna on 1/27/2014.
//  Copyright (c) 2014 Jeremy Tregunna. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^BindingFunction)(id value);

#define Bind(obj, kp) [Binding bindTarget:(obj) keyPath:(@"" # kp)]

/** This class is used to create a lightweight binding for the iOS platform.
 */
@interface Binding : NSObject

/**-----------------------------------------
 * @name Creation
 *  -----------------------------------------
 */

/** Creates a new binding tied to the particular target/selector pair.
 @param target Object to bind to
 @param selector Selector to bind to
 @return Binding representing the target/selector.
 */
+ (instancetype)bindTarget:(id)target selector:(SEL)selector;

/** Creates a new binding tied to the particular target/keyPath pair.
 @param target Object to bind to
 @param keyPath Keypath to bind to
 @return Binding representing the target/keyPath.
 */
+ (instancetype)bindTarget:(id)target keyPath:(NSString*)keyPath;

// Operations

/** Register to receive an update through the supplied block.
 
 For instance, you may decide you wish to reload a tableview whenever the *results* variable changes its value.
 
    [Bind(self.dataSource, results) next:^(NSArray* newResults) {
        [self.tableView reloadData];
    }];
 
 @param fn A block taking a single argument, the new value to be passed into it.
 @return The binding
 */
- (instancetype)next:(BindingFunction)fn;

/** Signal to the binding to stop sending updates. */
- (void)complete;

/** Connects two bindings together.
 
 For instance, consider this source code:
 
    Binding* a = Bind(self, name);
    Binding* b = Bind(self.textField, text);
    Binding* c = [a joinWith:b];
    self.name = @"Tom";
    // self.textField.text automatically gets set the string @"Tom".
 
 @param destination The destination binding
 @return The receiver after being connected with the destination.
 */
- (instancetype)joinWith:(Binding*)binding;

@end
