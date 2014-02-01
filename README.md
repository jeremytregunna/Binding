# Binding

[![Build Status](https://secure.travis-ci.org/jeremytregunna/Binding.png)](http://travis-ci.org/jeremytregunna/Binding)

There are many options for bindings in iOS, not the least of which being ReactiveCocoa. While RAC is great, and you should seriously consider using it for your applications, sometimes you need just a simple binding, and words like `flatMap`, `command` and `signal` can be intimidating for your teammates. This is why I built Binding.

The goal of Binding is to fill that spot—The "less scary"—observables spot.

## Example

Let's assume that in your view controller, you have a tableview, and you follow good design practices in separating your data source into a separate object. It manages loading of your resources, and changes a publicly visible property. This is your indication on when to reload the tableview! We can do that easily:

```objc
self.resultsBinding = [Bind(self.dataStore, results) next:^(id value) {
    [self.tableView reloadData];
}];
```

But what if you are loading a comment view, and you also want to update the title with the count of items that come in? Well, the new value is passed to your next block. Consider extending the above like so:

```objc
self.resultsBinding = [Bind(self.dataStore, results) next:^(NSArray* results) {
    self.title = [NSString stringWithFormat:@"Comments (%tu)", [results count]];

    [self.tableView reloadData];
}];
```

We don't have to stop there however, if you want to debug what's coming back from that, you could modify the block directly, or add another next block like so:

```objc
[self.resultsBinding next:^(NSArray* results) {
    NSLog(@"results = %@", results);
}];
```

Both blocks will be called when the results change.

## License

The terms under which use and distribution of this library is governed may be found in the [LICENSE](https://github.com/jeremytregunna/Binding/blob/master/LICENSE) file.
