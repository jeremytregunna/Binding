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
    if(!_completed)
        [self complete];

    _target  = nil;
    _keyPath = nil;
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

#pragma mark - Private Operations

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

#pragma mark - Public Operations

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
    if(!_completed)
    {
        self.completed = YES;
        [self.nextBlocks removeAllObjects];
        [_target removeObserver:self forKeyPath:_keyPath context:BindingContext];
    }
}

- (instancetype)relate:(Binding*)binding
{
    return [self next:^(id value) {
        [binding.target setValue:value forKeyPath:binding.keyPath];
    }];
}

@end
