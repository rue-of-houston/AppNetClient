//
//  ViewController.m
//  AppNetClient
//
//  Created by Rueben Anderson on 11/1/13.
//  Copyright (c) 2013 Rueben Anderson. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

typedef enum {
    LOADING_TIMELINE = 0,
    LOADING_IMAGES
} connectionTypes;

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    imageUrls = [[NSMutableDictionary alloc] init];
    userImages = [[NSMutableDictionary alloc] init];
    
    connectionType = LOADING_TIMELINE;
    
    // retrieve the timelined data
    [self makeRequest:@"https://alpha-api.app.net/stream/0/posts/stream/global"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // return a cell for each of the objects held in the array
    return [timelineDetails count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // set the cell identifier
    NSString *cellID = @"cell";
    
    // try to reuse a previously created tableview cell
    CustomCell *cell = [postTable dequeueReusableCellWithIdentifier:cellID];
    
    // no cell returned
    if (cell == nil)
    {
        // load the custom cell nib file
        NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:@"CustomCell" owner:self options:nil];
        
        // verify the array is valid
        if (bundle != nil)
        {
            // create tableview cell from the nib
            cell = (CustomCell *) [bundle objectAtIndex:0];
        }
    }
    
    NSString *username = [[timelineDetails objectAtIndex:indexPath.row] objectForKey:@"poster_username"];
    NSString *post = [[timelineDetails objectAtIndex:indexPath.row] objectForKey:@"post_text"];
    CGRect frame = [post boundingRectWithSize:CGSizeMake(227.0f, 53.0f) options:NSStringDrawingUsesLineFragmentOrigin attributes:nil context:nil];
    
    textHeight = frame.size.height;
    
    // set the cell data
    cell.username.text = username;
    cell.postText.text = post;
    cell.imageView.image = [userImages objectForKey:username];
    
    // round the corners of the images
    CALayer *layer = [cell.imageView layer];
    [layer setMasksToBounds:YES];
    [layer setCornerRadius:10.0f];
    [layer setBorderColor:[[UIColor lightGrayColor] CGColor]];
    [layer setBorderWidth:1.25f];

    
    // return the table cell
    return cell;
}

- (void)makeRequest:(NSString *) urlString
{
    // create the url object pointing to the timeline data
    NSURL *url = [NSURL URLWithString: urlString];
    
    if (connectionManager)
    {
        // stop any active requests
        [connectionManager cancel];
    }
    
    // verify that the url is valid
    if (url != nil)
    {
        // create a request object from the url
        NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
        
        // verify that the request is valid
        if (request != nil)
        {
            // create a new connection from the request object
            connectionManager = [[NSURLConnection alloc] initWithRequest:request delegate:self];
            
            // verify that the connection object is valid
            if (connectionManager != nil)
            {
                // start the connection
                [connectionManager start];
            }
        }
    }
    
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if (connectionType == LOADING_TIMELINE)
    {
        if (timelineData == nil)
        {
            // set the timeline data to equal the first bit of data received
            timelineData = (NSMutableData *) [data mutableCopy];
        }
        else
        {
            // append the received data
            [timelineData appendData:data];
        }
    }
    else if (connectionType == LOADING_IMAGES)
    {
        if (avatarData == nil)
        {
            // set the avatar image to equal the first bit of data
            avatarData = (NSMutableData *) [data mutableCopy];
        }
        else
        {
            // append the received data
            [avatarData appendData:data];
        }
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    // nullify the connection object
    connectionManager = nil;

    if (connectionType == LOADING_TIMELINE)
    {
        NSError *err;
        
        // create json object from the returned data
        timelineJSON = [NSJSONSerialization JSONObjectWithData:timelineData options:NSJSONReadingMutableLeaves error:&err];
        
        // reset the timeline data
        timelineData = nil;
        
        // set the connection loading type to allow for dynamic loading of user avatars
        connectionType = LOADING_IMAGES;
        
        // call the method to retrieve the table data from the json returned
        [self extractJSONCellData];
        
    }
    else if (connectionType == LOADING_IMAGES)
    {
        UIImage *avatar = [UIImage imageWithData:avatarData];

        
        if (avatar != nil)
        {
            // add the avatar image to dictionary of poster images
            [userImages setObject:avatar forKey:currentPoster];
            
            // reset the data
            avatarData = nil;
        }
        
        if ([userImages count] < [imageUrls count])
        {
            // create the url from the url stored in the dictionary at the current image index in the details array
            NSString *url = [[timelineDetails objectAtIndex:currentImage] objectForKey:@"poster_avatar_url"];
            
            // set the currentPoster string for image caching
            currentPoster = [[timelineDetails objectAtIndex:currentImage] objectForKey:@"poster_username"];
            
            // verify that the url is valid
            if (url != nil)
            {
                // initiate the request for downloading user avatar
                [self makeRequest:url];
            }
            
            // increment the current image index
            currentImage++;
        }
        else
        {
            [postTable reloadData];
            
            currentImage = 0;
        }
        
    }
    
}

- (void)extractJSONCellData
{
    // retrieve the data array from the returned json object
    NSArray *posts = [timelineJSON objectForKey:@"data"];
    
    // create an empy array for holding the extracted dictionaries
    timelineDetails = [[NSMutableArray alloc] init];
    
    // verify that the posts object is valid
    if (posts != nil)
    {
        // iterate over the posts array to extract the required information from each of its housed dictionaries
        for (int i = 0; i < [posts count]; i++)
        {
            // create a container dictionary object for holding the extracted post data
            NSMutableDictionary *postDetails = [[NSMutableDictionary alloc] init];
            
            // create an nsdicitonary object for each object in the returned array
            NSDictionary *postData = [posts objectAtIndex:i];
            
            // extract the required data and set them to strings
            NSString *post = [postData objectForKey:@"text"];
            NSString *username = [[postData objectForKey:@"user"] objectForKey:@"username"];
            NSString *name = [[postData objectForKey:@"user"] objectForKey:@"name"];
            NSString *details = [[[postData objectForKey:@"user"] objectForKey:@"description"] objectForKey:@"text"];
            NSString *postCreation = [postData objectForKey:@"created_at"];
            NSString *avatarUrl = [[[postData objectForKey:@"user"] objectForKey:@"avatar_image"] objectForKey:@"url"];
            
            // set blank text where text returns null
            if (details == nil)
            {
                details = @"";
            }
            
            // add the extracted json data to the dictionary
            [postDetails setObject:post forKey:@"post_text"];
            [postDetails setObject:username forKey:@"poster_username"];
            [postDetails setObject:name forKey:@"poster_name"];
            [postDetails setObject:details forKey:@"poster_details"];
            [postDetails setObject:postCreation forKey:@"post_date"];
            [postDetails setObject:avatarUrl forKey:@"poster_avatar_url"];
            
            if (imageUrls != nil)
            {
                // add the url to the global url dictionary object
                [imageUrls setObject:avatarUrl forKey:username];
            }
            
            if (timelineDetails != nil)
            {
                // add the posting details dictionary to the timeline array
                [timelineDetails addObject:postDetails];
            }
        }
    }
    
   if (userImages != nil && [userImages count] < [imageUrls count])
   {
       // create the url from the url stored in the dictionary at the current image index in the details array
       NSString *url = [[timelineDetails objectAtIndex:currentImage] objectForKey:@"poster_avatar_url"];
       
       // set the currentPoster string for image caching
       currentPoster = [[timelineDetails objectAtIndex:currentImage] objectForKey:@"poster_username"];
       
       // increment the current image index
       currentImage++;
       
       // verify that the url is valid
       if (url != nil)
       {
           // initiate the request for downloading user avatar
           [self makeRequest:url];
       }

   }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    int cellHeight = 80;
    
    if (textHeight > cellHeight)
    {
        cellHeight += 17;
    }
    
    return cellHeight;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    
    // grab the scroll offset
    float offset = scrollView.contentOffset.y;
    
    // if the scroll is decelerating and the pull 90pts from top, do a refresh
    if (decelerate && offset <= -90.0f)
    {
        connectionType = LOADING_TIMELINE;
        
        // retrieve the timelined data
        [self makeRequest:@"https://alpha-api.app.net/stream/0/posts/stream/global"];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
   
}



@end
