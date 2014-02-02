# Binding

[![Build Status](https://secure.travis-ci.org/jeremytregunna/Binding.png)](http://travis-ci.org/jeremytregunna/Binding)

Binding is a library that provides an implementation of a time-varying variable.
It is an essential ingredient for any reactive system.

This library is intended, not as a replacement for a functional-reactive
library, such as [ReactiveCocoa](https://github.com/ReactiveCocoa/ReactiveCocoa), but as a less-scary, tool which allows
you to write code in a reactive way. It's also a wonderful way to remove
a lot of boilerplate typically invovled with managing state.

## Example

Let's assume that in your view controller, you have a tableview, and you follow
good design practices in separating your data source into a separate object. It
manages loading of your resources, and changes a publicly visible property. This
is your indication on when to reload the tableview! We can do that easily:

```objc
self.resultsBinding = [Bind(self.dataStore, results) next:^(id value) {
    [self.tableView reloadData];
}];
```

But what if you are loading a comment view, and you also want to update the
title with the count of items that come in? Well, the new value is passed to
your next block. Consider extending the above like so:

```objc
self.resultsBinding = [Bind(self.dataStore, results) next:^(NSArray* results) {
    self.title = [NSString stringWithFormat:@"Comments (%tu)", [results count]];

    [self.tableView reloadData];
}];
```

We don't have to stop there however, if you want to debug what's coming back
from that, you could modify the block directly, or add another next block like
so:

```objc
[self.resultsBinding next:^(NSArray* results) {
    NSLog(@"results = %@", results);
}];
```

Both blocks will be called when the results change.

## Boilerplate Removal

In the introduction there is a mention about helping remove some boilerplate
code when managing state. An example of this can be seen in an implementaiton
of a UITableViewCell, like the one below:

```objc
// Header

@interface Cell : UITableViewCell
@property (nonatomic, copy) NSString* name;
@end

// Implementation

@interface Cell ()
@property (nonatomic, weak) IBOutlet UILabel* nameLabel;
@end

@implementation Cell

- (void)setName:(NSString*)name
{
    [self willChangeValueForKey:@"name"];
    _name = [name copy];
    self.nameLabel.text = _name;
    [self didChangeValueForKey:@"name"];
}

@end
```

Now, imagine you have a more complicated cell which has 10 properties, and you
are only exposing minimal state on the public interface, letting the cell do
the work of placing that state where it knows is best. You then conceivably
have 10 custom setters, all basically doing the same thing: Setting some local
instance level state, and some value on some subview. This is less than ideal.

Consider then, this implementation, using binding.

```objc
// Implementation

@interface Cell ()
@property (nonatomic, weak) IBOutlet UILabel* nameLabel;
@property (nonatomic, strong) Binding* nameBinding;
@end

@implementation Cell

- (void)awakeFromNib
{
    [super awakeFromNib];

    self.nameBinding = [Bind(self, name) relate:Bind(self.nameLabel, text)];
}

@end
```

Here, we remove the need for any custom setters, just maintaining a strong
reference to the binding, which we create binding the public `name` string
property, and relating that to a binding to the `text` property on the
`self.nameLabel` object. In simple terms, what this means, is whenever this code
is hit:

```objc
cell.name = @"Tom";
```

Then the cell's `nameLabel` will receive that string, `@"Tom"` on its `text`
property. No need to override custom setters. This can reduce your view code by
as much as 500% in some cases.

That 500% figure above was gathered by taking a cell in one of my projects and
rewriting it in this style. The cell went from 126 lines of code, down to 25
while being 100% feature complete.

## License

The terms under which use and distribution of this library is governed may be
found in the [LICENSE](https://github.com/jeremytregunna/Binding/blob/master/LICENSE) file.
