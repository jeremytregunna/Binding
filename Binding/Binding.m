//
//  Binding.m
//  Binding
//
//  Created by Jeremy Tregunna on 1/27/2014.
//  Copyright (c) 2014 Jeremy Tregunna. All rights reserved.
//

#import "Binding.h"
#import <libkern/OSAtomic.h>

@interface Binding ()
@property (nonatomic) OSSpinLock lock;
@property (nonatomic, strong) id target;
@property (nonatomic, copy) NSString* keyPath;
@property (nonatomic, getter=isEvaluating) BOOL evaluating;
@property (nonatomic) BOOL needsEvaluation;
@property (nonatomic, strong) NSMutableArray* nextBlocks;
@property (nonatomic) BOOL completed;
@end

@implementation Binding

+ (instancetype)bindTarget:(id)target selector:(SEL)selector
{
    return [[self alloc] initWithTarget:target keyPath:NSStringFromSelector(selector)];
}

+ (instancetype)bindTarget:(id)target keyPath:(NSString*)keyPath
{
    return [[self alloc] initWithTarget:target keyPath:keyPath];
}

- (instancetype)initWithTarget:(id)target keyPath:(NSString*)keyPath
{
    if((self = [super init]))
    {
        _target             = target;
        _keyPath            = [keyPath copy];
        _evaluating         = NO;
        _nextBlocks         = [NSMutableArray array];
        _lock               = OS_SPINLOCK_INIT;

        [_target addObserver:self forKeyPath:keyPath options:0 context:BindingContext];
    }
    return self;
}

- (void)dealloc
{
    [_target removeObserver:self forKeyPath:_keyPath context:BindingContext];
}

#pragma mark - KVO

static void* BindingContext = &BindingContext;

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
    if(context == BindingContext)
        [self invalidate];
    else
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

#pragma mark - Operations

- (void)invalidate
{
    self.needsEvaluation = YES;
    [self evaluate];
}

- (void)evaluate
{
    if(![self isEvaluating] && [self needsEvaluation])
    {
        self.evaluating      = YES;
        id value             = [self.target valueForKeyPath:self.keyPath];

        if(value != nil)
        {
            for(BindingFunction fn in self.nextBlocks)
                fn(value);
        }

        self.needsEvaluation = NO;
        self.evaluating      = NO;
    }
}

- (instancetype)next:(BindingFunction)fn
{
    BindingFunction f = [fn copy];

    OSSpinLockLock(&_lock);
    [self.nextBlocks addObject:f];
    OSSpinLockUnlock(&_lock);

    return self;
}

- (void)complete
{
    [self.nextBlocks removeAllObjects];
    self.completed = YES;
}

@end
