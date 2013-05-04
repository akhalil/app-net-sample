//
//  PostsViewController.m
//  AppNet
//
//  Created by Ahmed Khalil on 4/3/13.
//  Copyright (c) 2013 ChaiONE. All rights reserved.
//

#import "PostsViewController.h"
#import "ANPost.h"
#import <QuartzCore/QuartzCore.h>

NSString * const kAppNetPostsURL = @"https://alpha-api.app.net/stream/0/posts/stream/global";
CGFloat const kTextFontSize = 18.0;
CGFloat const kDetailFontSize = 14.0;
int const kExtraSpace = 25;
int const kMarginSpace = 10;

float const kCellImageWidth = 52;



@interface PostsViewController ()

@property (nonatomic, strong) NSMutableArray *items;

@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property (nonatomic, strong) NSMutableDictionary *postToImageOperation;

@end

@implementation PostsViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)awakeFromNib
{
    self.operationQueue = [[NSOperationQueue alloc] init];
    self.items = [[NSMutableArray alloc] init];
    self.postToImageOperation = [NSMutableDictionary dictionary];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    
    [self refreshPosts];
    
    //Pull to refresh should be implemented to refresh the timeline
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self
                       action:@selector(refreshPosts)
             forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
    
    self.tableView.rowHeight = kCellImageWidth;
}

- (void)refreshPosts
{
    [self.postToImageOperation removeAllObjects];
    [self.operationQueue cancelAllOperations];
    
    [self refreshPostsWithCompletion:^(id obj, NSError *err) {
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if (!err) {
                [self.items removeAllObjects];
                
                for (NSDictionary *dict in obj) {
                    //NSLog(@"Post = %@", dict);
                    
                    [self.items addObject:[[ANPost alloc] initWithJSONDictionary:dict]];
                }
                // Each post should be rendered in a table view cell, with the most recent at the top.
                NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createdAt"
                                                                               ascending:NO];
                [self.items sortUsingDescriptors:@[sortDescriptor]];
                [self.tableView reloadData];
                if (self.refreshControl.refreshing) {
                    [self.refreshControl endRefreshing];
                }
            }
            else {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Unable to get posts" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alertView show];
            }
        }];
    }];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)refreshPostsWithCompletion:(void (^)(id obj, NSError *err))completionBlock
{
    // App.net API
    NSURL *url = [[NSURL alloc] initWithString:kAppNetPostsURL];
    NSURLRequest *newReq = [[NSURLRequest alloc] initWithURL:url];
    
    void (^completionHandler)(NSURLResponse *urlResponse, NSData *responseData, NSError *error) = ^(NSURLResponse *urlResponse, NSData *responseData, NSError *error)
    {
        if (!error) {
            
            id obj = [NSJSONSerialization JSONObjectWithData:responseData
                                                     options:kNilOptions
                                                       error:&error];
            //NSLog(@"%@", obj);
            if (!error) {
                
                obj = [obj valueForKey:@"data"];
                if ([obj isKindOfClass:[NSDictionary class]]) {
                    obj = @[obj];
                }
                
                completionBlock(obj, nil);
            }
            else {
                completionBlock(nil, error);
            }
        }
        else {
            completionBlock(nil, error);
        }
    };
    [NSURLConnection sendAsynchronousRequest:newReq
                                       queue:self.operationQueue//[NSOperationQueue currentQueue]
                           completionHandler:completionHandler];
}

#pragma mark - Table view data source

//- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
//{
//#warning Potentially incomplete method implementation.
//    // Return the number of sections.
//    return 0;
//}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"PostCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    
    ANPost *post = [self.items objectAtIndex:indexPath.row];
    // Each cell should contain the poster's name in bold
    cell.textLabel.text = post.name;
    cell.detailTextLabel.text = post.text;
    
    // Each cell should contain the user's avatar (bonus if the corners are rounded)
    if (post.avatarImage) {
        [self configureImageView:cell.imageView withImage:post.avatarImage];
    }
    else {
        // The list should scroll quickly, without dropping frames on an iPhone 5
        NSBlockOperation *operation = [[NSBlockOperation alloc] init];
        
        // use weak reference inside the block to avoid a retain cycle
        __weak NSBlockOperation *weakOperation = operation;
        
        [operation addExecutionBlock:^{
            
            if ([weakOperation isCancelled]) {
                return;
            }
            
            NSURL *url = [NSURL URLWithString:post.avatarImageUrl];
            UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:url]];
            
            CGSize itemSize = CGSizeMake(kCellImageWidth, kCellImageWidth);
            UIGraphicsBeginImageContext(itemSize);
            CGRect imageRect = CGRectMake(0.0, 0.0, itemSize.width, itemSize.height);
            [image drawInRect:imageRect];
            image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                UITableViewCell *originalCell = [tableView cellForRowAtIndexPath:indexPath];
                [self configureImageView:originalCell.imageView withImage:image];
                ANPost *originalPost = [self.items objectAtIndex:indexPath.row];
                [originalCell setNeedsLayout];
                originalPost.avatarImage = image;
            }];
        }];
        // Could be a placeholder image
        cell.imageView.image = [UIImage imageNamed:@"avatar"];
        [self.operationQueue addOperation:operation];
        [self.postToImageOperation setObject:operation forKey:post.avatarImageUrl];
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    ANPost *post = [self.items objectAtIndex:indexPath.row];
    NSOperation *operation = [self.postToImageOperation objectForKey:post.avatarImageUrl];
    if (operation) {
        [operation cancel];
        [self.postToImageOperation removeObjectForKey:post.avatarImageUrl];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Each cell should contain the post text, and be variable height, depending on the text size
    ANPost *post = [self.items objectAtIndex:indexPath.row];
    //CGFloat defaultHeight = [super tableView:tableView heightForRowAtIndexPath:indexPath];
    CGFloat contentHeight = [self heightOfContent:post.text withFontOfSize:kDetailFontSize];
    CGFloat headerHeight =  [self heightOfContent:post.name withFontOfSize:kTextFontSize];
    
    return headerHeight + contentHeight + kExtraSpace;
}

//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    // Navigation logic may go here. Create and push another view controller.
//    /*
//     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
//     // ...
//     // Pass the selected object to the new view controller.
//     [self.navigationController pushViewController:detailViewController animated:YES];
//     */
//}

#pragma mark - Common methods

- (void)configureImageView:(UIImageView *)imageView withImage:(UIImage *)image
{
    imageView.image = image;
    imageView.layer.masksToBounds = YES;
    imageView.layer.cornerRadius = 9.0;
}

- (CGFloat)heightOfContent:(NSString *)label withFontOfSize:(CGFloat)fontSize
{
    CGFloat contentHeight = [label sizeWithFont:[UIFont systemFontOfSize:fontSize]
                              constrainedToSize:CGSizeMake(self.tableView.bounds.size.width - kCellImageWidth - kMarginSpace, MAXFLOAT)
                                  lineBreakMode:NSLineBreakByWordWrapping].height;
    return contentHeight;
}


@end
