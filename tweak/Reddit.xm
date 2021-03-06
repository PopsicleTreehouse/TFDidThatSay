
#import "Reddit.h"
#import "assets/TFHelper.h"

static BOOL isRedditEnabled;
static BOOL isTFDeletedOnly;
static CGFloat pushshiftRequestTimeoutValue;

int firstVersionPart = 2020;
int secondVersionPart = 0;

%group Reddit_v4_current

%hook CommentTreeNode
%property(assign,nonatomic)id commentTreeHeaderNode;
%property(assign,nonatomic)id commentTreeCommandBarNode;
%end

%hook CommentTreeHeaderView

-(void) layoutSubviews{
	%orig;
	
	[[self commentTreeNode] setCommentTreeHeaderNode:self];
}

%end

%hook CommentTreeHeaderNode

-(void) didLoad{
	%orig;
	
	[[self commentTreeNode] setCommentTreeHeaderNode:self];
}
%end


%hook CommentTreeCommandBarNode

-(void) didLoad{
	%orig;

	[[self commentTreeNode] setCommentTreeCommandBarNode:self];
}
%end


%hook CommentActionSheetViewController

-(void) setItems:(id) arg1{
	
	NSString *commentBody = [[self comment] bodyText];
	
	if ([%c(TFHelper) shouldShowUndeleteButtonWithInfo:commentBody isDeletedOnly:isTFDeletedOnly]){

		UIImage* origImage = [UIImage imageWithContentsOfFile:@"/var/mobile/Library/Application Support/TFDidThatSay/eye160dark.png"];

		CGSize existingImageSize = [[arg1[0] leftIconImage] size];
		CGFloat scale = origImage.size.width / existingImageSize.width;

		UIImage *newImage = [UIImage imageWithCGImage:[origImage CGImage] scale:scale orientation:origImage.imageOrientation];

		id undeleteItem = [[%c(RUIActionSheetItem) alloc] initWithLeftIconImage:newImage text:@"TF did that say?" identifier:@"undeleteItemIdentifier" context:[self comment]];

		arg1 = [arg1 arrayByAddingObject:undeleteItem];
		
		[undeleteItem release];
	}
	
	%orig;
}

-(void) handleDidSelectActionSheetItem:(id) arg1{
	%orig;
	
	if ([[arg1 identifier] isEqualToString:@"undeleteItemIdentifier"]){
		
		[self dismissViewControllerAnimated:YES completion:nil];	
		
		id commentTreeNode = [self commentTreeNode];
		Comment *comment = [commentTreeNode comment];
		
		[%c(TFHelper) getUndeleteDataWithID:[[comment pk] componentsSeparatedByString:@"_"][1] isComment:YES timeout:pushshiftRequestTimeoutValue extraData:nil completionTarget:self completionSelector:@selector(completeUndeleteCommentAction:)];
	}
}

%new 
-(void) completeUndeleteCommentAction:(NSDictionary *) data{
	
	id commentTreeNode = [self commentTreeNode];
	Comment *comment = [commentTreeNode comment];
	
	NSString *author = data[@"author"];
	NSString *body = data[@"body"];
		
	NSMutableAttributedString *bodyMutableAttributedText;
			
	id themeManager;
	id isNightMode;
	id textColor;
	
	if (firstVersionPart == 2020){
		themeManager = [[%c(ThemeManager) alloc] initWithAppSettings:[%c(AppSettings) sharedSettings]];
		isNightMode = [[[%c(AccountManager) sharedManager] defaults] objectForKey:@"kUseNightKey"];
		
		if (isNightMode) {
			textColor = [[themeManager darkTheme] bodyTextColor];
		} else{
			textColor = [[themeManager lightTheme] bodyTextColor];
		}
		
		[themeManager release];
	} else {
	
		if (secondVersionPart >= 45){
			themeManager = [[%c(ThemeManager) alloc] initWithAppSettings:[%c(AppSettings) sharedSettings]];
			isNightMode = [[[%c(AccountManager) sharedManager] defaults] objectForKey:@"kUseNightKey"];
			
			if (isNightMode) {
				textColor = [[themeManager darkTheme] bodyTextColor];
			} else{
				textColor = [[themeManager lightTheme] bodyTextColor];
			}
			
			[themeManager release];
			
		} else if (secondVersionPart >= 37){
			themeManager  = [[%c(ThemeManager) alloc] initWithTraitCollection:nil appSettings:[%c(AppSettings) sharedSettings]];
			isNightMode = [[[%c(AccountManager) sharedManager] defaults] objectForKey:@"kUseNightKey"];
			
			if (isNightMode) {
				textColor = [[themeManager nightTheme] bodyTextColor];
			} else{
				textColor = [[themeManager dayTheme] bodyTextColor];
			}
			
			[themeManager release];
			
		} else {
			themeManager  = [%c(ThemeManager) sharedManager];
			isNightMode = [[[%c(AccountManager) sharedManager] defaults] objectForKey:@"kUseNightKey"];
			
			if (isNightMode) {
				textColor = [[themeManager nightTheme] bodyTextColor];
			} else{
				textColor = [[themeManager dayTheme] bodyTextColor];
			}
		}
	}
		
	bodyMutableAttributedText = [[NSMutableAttributedString alloc] initWithAttributedString:[%c(NSAttributedStringMarkdownParser) attributedStringUsingCurrentConfig:body]];

	[bodyMutableAttributedText beginEditing];
	[bodyMutableAttributedText enumerateAttribute:NSForegroundColorAttributeName inRange:NSMakeRange(0, bodyMutableAttributedText.length) options:0 usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
		[bodyMutableAttributedText removeAttribute:NSForegroundColorAttributeName range:range]; 
		[bodyMutableAttributedText addAttribute:NSForegroundColorAttributeName value:textColor range:range];
	}];
	[bodyMutableAttributedText endEditing];
	
	[comment setAuthor:author];
	[comment setBodyText:body];
	[comment setBodyRichTextAttributed:bodyMutableAttributedText];
	[comment setBodyAttributedText:bodyMutableAttributedText];
	
	[[commentTreeNode commentTreeHeaderNode] updateContentViewsForData:comment];

	[bodyMutableAttributedText release];
}

%end


%hook PostDetailViewController
%property(strong,nonatomic) id feedPostTextWithThumbnailNode;
%property(strong,nonatomic) id feedPostDetailCellNode;
%end

%hook FeedPostDetailCellNode

-(void) didLoad{
	%orig;
	
	[[[self delegate] viewController] setFeedPostDetailCellNode:self];
}
%end

%hook PostActionSheetViewController

-(void) setItems:(id) arg1{
	
	Post *post = [self post];
	NSString *postBody = [post selfText];
	
	if ([post isSelfPost]){
		if ([%c(TFHelper) shouldShowUndeleteButtonWithInfo:postBody isDeletedOnly:isTFDeletedOnly]){

			UIImage* origImage = [UIImage imageWithContentsOfFile:@"/var/mobile/Library/Application Support/TFDidThatSay/eye160dark.png"];

			CGSize existingImageSize = [[arg1[0] leftIconImage] size];
			CGFloat scale = origImage.size.width / existingImageSize.width;

			UIImage *newImage = [UIImage imageWithCGImage:[origImage CGImage] scale:scale orientation:origImage.imageOrientation];

			id undeleteItem = [[%c(RUIActionSheetItem) alloc] initWithLeftIconImage:newImage text:@"TF did that say?" identifier:@"undeleteItemIdentifier" context:[self post]];

			arg1 = [arg1 arrayByAddingObject:undeleteItem];
			
			[undeleteItem release];
		}
	}
	
	%orig;
}


-(void) handleDidSelectActionSheetItem:(id) arg1{
	%orig;
	
	if ([[arg1 identifier] isEqualToString:@"undeleteItemIdentifier"]){
		
		[self dismissViewControllerAnimated:YES completion:nil];
		
		Post *post = [self post];
		
		if ([post isSelfPost]){
			
			[%c(TFHelper) getUndeleteDataWithID:[[post pk] componentsSeparatedByString:@"_"][1] isComment:NO timeout:pushshiftRequestTimeoutValue extraData:nil completionTarget:self completionSelector:@selector(completeUndeletePostAction:)];
		}	
	}
}

%new
-(void) completeUndeletePostAction:(NSDictionary *) data{
	Post *post = [self post];
	
	NSString *author = data[@"author"];
	NSString *body = data[@"body"];
	
	id themeManager;
	id isNightMode;
	id textColor;
	
	if (firstVersionPart == 2020){
		themeManager = [[%c(ThemeManager) alloc] initWithAppSettings:[%c(AppSettings) sharedSettings]];
		isNightMode = [[[%c(AccountManager) sharedManager] defaults] objectForKey:@"kUseNightKey"];
		
		if (isNightMode) {
			textColor = [[themeManager darkTheme] bodyTextColor];
		} else{
			textColor = [[themeManager lightTheme] bodyTextColor];
		}
		
		[themeManager release];
	} else {
		
		if (secondVersionPart >= 45){
			themeManager = [[%c(ThemeManager) alloc] initWithAppSettings:[%c(AppSettings) sharedSettings]];
			isNightMode = [[[%c(AccountManager) sharedManager] defaults] objectForKey:@"kUseNightKey"];
			
			if (isNightMode) {
				textColor = [[themeManager darkTheme] bodyTextColor];
			} else{
				textColor = [[themeManager lightTheme] bodyTextColor];
			}
			
			[themeManager release];
			
		} else if (secondVersionPart >= 37){
			themeManager  = [[%c(ThemeManager) alloc] initWithTraitCollection:nil appSettings:[%c(AppSettings) sharedSettings]];
			isNightMode = [[[%c(AccountManager) sharedManager] defaults] objectForKey:@"kUseNightKey"];
			
			if (isNightMode) {
				textColor = [[themeManager nightTheme] bodyTextColor];
			} else{
				textColor = [[themeManager dayTheme] bodyTextColor];
			}
			
			[themeManager release];
			
		} else {
			themeManager  = [%c(ThemeManager) sharedManager];
			isNightMode = [[[%c(AccountManager) sharedManager] defaults] objectForKey:@"kUseNightKey"];
			
			if (isNightMode) {
				textColor = [[themeManager nightTheme] bodyTextColor];
			} else{
				textColor = [[themeManager dayTheme] bodyTextColor];
			}
		}			
	}
	
	NSMutableAttributedString *bodyMutableAttributedText = [[NSMutableAttributedString alloc] initWithAttributedString:[%c(NSAttributedStringMarkdownParser) attributedStringUsingCurrentConfig:body]];

	[bodyMutableAttributedText beginEditing];
	[bodyMutableAttributedText enumerateAttribute:NSForegroundColorAttributeName inRange:NSMakeRange(0, bodyMutableAttributedText.length) options:0 usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
		[bodyMutableAttributedText removeAttribute:NSForegroundColorAttributeName range:range]; 
		[bodyMutableAttributedText addAttribute:NSForegroundColorAttributeName value:textColor range:range];
	}];
	[bodyMutableAttributedText endEditing];

	[post setSelfText:body];
	[post setAuthor:author];
	[post setSelfPostRichTextAttributed:bodyMutableAttributedText];
	[post setPreviewFeedPostTextString:bodyMutableAttributedText];
	
	if (firstVersionPart == 2020){
		[[[[[self postActionSheetDelegate] controller] feedPostDetailCellNode] contentNode] configureSelfTextNode];
	} else {
		if (secondVersionPart >= 44){
			[[[[[self postActionSheetDelegate] controller] feedPostDetailCellNode] contentNode] configureSelfTextNode];
		} else if (secondVersionPart >= 38) {
			[[[[self postActionSheetDelegate] controller] feedPostDetailCellNode] configureSelfTextNode];
		} else {
			[[[[self postActionSheetDelegate] controller] feedPostDetailCellNode] configureSelfTextNode];
			[[[[[self postActionSheetDelegate] controller] feedPostDetailCellNode] titleNode] configureNodes];
		}
	}
	
	[bodyMutableAttributedText release];
}

%end

%end


%group Reddit_v4_ios10

%hook CommentsViewController

%new 
-(void) updateComments{
	[self reloadCommentsWithNewCommentsHighlight:NO autoScroll:NO animated:NO];
}

%new 
-(void) updatePostText{
	
	if (secondVersionPart >= 2){
		[self reloadPostSection:YES];
	} else {
		[self feedPostViewDidUpdatePost:[self postData] shouldReloadFeed:NO];
	}	
}

%end

%hook CommentActionSheetViewController

-(void) setItems:(id) arg1{
	
	NSString *commentBody = [[self comment] bodyText];
	
	if ([%c(TFHelper) shouldShowUndeleteButtonWithInfo:commentBody isDeletedOnly:isTFDeletedOnly]){

		UIImage* origImage = [UIImage imageWithContentsOfFile:@"/var/mobile/Library/Application Support/TFDidThatSay/eye160dark.png"];

		CGSize existingImageSize = [[arg1[0] leftIconImage] size];
		CGFloat scale = origImage.size.width / existingImageSize.width;

		UIImage *newImage = [UIImage imageWithCGImage:[origImage CGImage] scale:scale orientation:origImage.imageOrientation];
		
		id undeleteItem;
		
		if (secondVersionPart >= 18) {
			undeleteItem = [[%c(RUIActionSheetItem) alloc] initWithLeftIconImage:newImage text:@"TF did that say?" identifier:@"undeleteItemIdentifier" context:[self comment]];
		} else {
			undeleteItem = [[%c(ActionSheetItem) alloc] initWithLeftIconImage:newImage text:@"TF did that say?" identifier:@"undeleteItemIdentifier" context:[self comment]];
		}

		arg1 = [arg1 arrayByAddingObject:undeleteItem];
		
		[undeleteItem release];
	}
	
	%orig;
}

// >= 4.21
-(void) handleDidSelectActionSheetItem:(id) arg1{
	%orig;
	
	if ([[arg1 identifier] isEqualToString:@"undeleteItemIdentifier"]){
		
		[self dismissViewControllerAnimated:YES completion:nil];	
		
		Comment *comment = [self comment];
		
		[%c(TFHelper) getUndeleteDataWithID:[[comment pk] componentsSeparatedByString:@"_"][1] isComment:YES timeout:pushshiftRequestTimeoutValue extraData:nil completionTarget:self completionSelector:@selector(completeUndeleteCommentAction:)];
	}
}

// <= 4.20
-(void) actionSheetViewController:(id) arg1 didSelectItem:(id) arg2{
	%orig;
	
	if ([[arg2 identifier] isEqualToString:@"undeleteItemIdentifier"]){
		
		[self dismissViewControllerAnimated:YES completion:nil];	
		
		Comment *comment = [self comment];
		
		[%c(TFHelper) getUndeleteDataWithID:[[comment pk] componentsSeparatedByString:@"_"][1] isComment:YES timeout:pushshiftRequestTimeoutValue extraData:nil completionTarget:self completionSelector:@selector(completeUndeleteCommentAction:)];
	}
}

%new 
-(void) completeUndeleteCommentAction:(NSDictionary *) data{
	
	Comment *comment = [self comment];
	
	NSString *body = data[@"body"];
	
	NSMutableAttributedString *bodyMutableAttributedText = [[NSMutableAttributedString alloc] initWithAttributedString:[%c(NSAttributedStringMarkdownParser) attributedStringUsingCurrentConfig:body]];
	
	[comment setAuthor:data[@"author"]];
	[comment setBodyText:body];
	[comment setBodyAttributedText:bodyMutableAttributedText];

	if (secondVersionPart >= 12) {
		[comment setBodyRichTextAttributed:bodyMutableAttributedText];
	}

	[[self commentActionSheetDelegate] updateComments];

	[bodyMutableAttributedText release];
}
%end


%hook PostActionSheetViewController

-(void) setItems:(id) arg1{
	
	Post *post = [self post];
	NSString *postBody = [post selfText];
	
	if ([post isSelfPost]){
		if ([%c(TFHelper) shouldShowUndeleteButtonWithInfo:postBody isDeletedOnly:isTFDeletedOnly]){

			UIImage* origImage = [UIImage imageWithContentsOfFile:@"/var/mobile/Library/Application Support/TFDidThatSay/eye160dark.png"];

			CGSize existingImageSize = [[arg1[0] leftIconImage] size];
			CGFloat scale = origImage.size.width / existingImageSize.width;

			UIImage *newImage = [UIImage imageWithCGImage:[origImage CGImage] scale:scale orientation:origImage.imageOrientation];
			
			id undeleteItem;
			
			if (secondVersionPart >= 18) {
				undeleteItem = [[%c(RUIActionSheetItem) alloc] initWithLeftIconImage:newImage text:@"TF did that say?" identifier:@"undeleteItemIdentifier" context:[self post]];
			} else {
				undeleteItem = [[%c(ActionSheetItem) alloc] initWithLeftIconImage:newImage text:@"TF did that say?" identifier:@"undeleteItemIdentifier" context:[self post]];
			}

			arg1 = [arg1 arrayByAddingObject:undeleteItem];
			
			[undeleteItem release];
		}
	}
	
	%orig;
}

// >= 4.21
-(void) handleDidSelectActionSheetItem:(id) arg1{
	%orig;
	
	if ([[arg1 identifier] isEqualToString:@"undeleteItemIdentifier"]){
		
		[self dismissViewControllerAnimated:YES completion:nil];
		
		Post *post = [self post];
		
		if ([post isSelfPost]){
			
			[%c(TFHelper) getUndeleteDataWithID:[[post pk] componentsSeparatedByString:@"_"][1] isComment:NO timeout:pushshiftRequestTimeoutValue extraData:nil completionTarget:self completionSelector:@selector(completeUndeletePostAction:)];
		}	
	}
}

// <= 4.20
-(void) actionSheetViewController:(id) arg1 didSelectItem:(id) arg2{
	%orig;
	
	if ([[arg2 identifier] isEqualToString:@"undeleteItemIdentifier"]){
		
		[self dismissViewControllerAnimated:YES completion:nil];
		
		Post *post = [self post];
		
		if ([post isSelfPost]){
			
			[%c(TFHelper) getUndeleteDataWithID:[[post pk] componentsSeparatedByString:@"_"][1] isComment:NO timeout:pushshiftRequestTimeoutValue extraData:nil completionTarget:self completionSelector:@selector(completeUndeletePostAction:)];
		}	
	}
}

%new
-(void) completeUndeletePostAction:(NSDictionary *) data{
	
	Post *post = [self post];
	
	NSString *body = data[@"body"];
	
	NSMutableAttributedString *bodyMutableAttributedText = [[NSMutableAttributedString alloc] initWithAttributedString:[%c(NSAttributedStringMarkdownParser) attributedStringUsingCurrentConfig:body]];
	
	[post setAuthor:data[@"author"]];
	[post setSelfText:body];
	[post setSelfTextAttributed:bodyMutableAttributedText];
	
	if (secondVersionPart >= 8) {
		[post setSelfPostRichTextAttributed:bodyMutableAttributedText];
	}
	
	if (secondVersionPart >= 15) {
		[post setPreviewFeedPostTextString:bodyMutableAttributedText];
	} 
	
	[[self postActionSheetDelegate] updatePostText];
	
	[bodyMutableAttributedText release];
}

%end

%end


//outdated and unchanged from first version of this tweak... 
//TODO: move button to menu, add post support, make async requests once I feel like doing it
%group Reddit_v3

%hook CommentView

%new
-(void) buttonAction {

	id commentsViewController = [self delegate];
	id comment = [self comment];

	NSError* error;

	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	[request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.pushshift.io/reddit/search/comment/?ids=%@&fields=author,body",[comment pkWithoutPrefix]]]];
	[request setHTTPMethod:@"GET"];

	NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&error];

	NSString *author = @"[author]";
	NSString *body = @"[body]";

	if (data != nil && error == nil){
		
		id jsonData = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
		   
		author = [[jsonData objectForKey:@"data"][0] objectForKey:@"author"];
		body = [[jsonData objectForKey:@"data"][0] objectForKey:@"body"];
		   
		if ([body isEqualToString:@"[deleted]"] || [body isEqualToString:@"[removed]"]){
			body = @"[comment was unable to be archived]";
		}
		
	} else if (error != nil || data == nil){
		body = @"[an error occured]";
	}

	[comment setValue:author forKey:@"author"];

	[comment setValue:[%c(MarkDownParser) attributedStringFromMarkdownString: body] forKey:@"bodyAttributedText"];
	[comment setValue:body forKey:@"bodyText"];

	[commentsViewController reloadCommentsWithNewCommentsHighlight:NO autoScroll:NO animated:NO];
}


-(id) initWithFrame:(id)arg1{
	id orig = %orig;
	id commandView = [self commandView];

	UIButton *undeleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[undeleteButton addTarget:self action:@selector(buttonAction) forControlEvents:UIControlEventTouchUpInside];

	UIImage* undeleteImage = [UIImage imageWithContentsOfFile:@"/var/mobile/Library/Application Support/TFDidThatSay/eye160dark.png"];
	
	[undeleteButton setImage:undeleteImage forState:UIControlStateNormal];

	[commandView setUndeleteButton:undeleteButton];
	[commandView addSubview:undeleteButton];

	return orig;
}


%end


%hook CommentCommandView
%property (assign, nonatomic) id undeleteButton;

-(void) layoutSubviews{
	%orig;

	UIButton *button = [self undeleteButton];

	button.frame = CGRectMake([[self overflowButton ] frame].origin.x - 32, 0, 32, 32);
}
%end

%end


static void loadPrefs(){
	NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/User/Library/Preferences/com.lint.undelete.prefs.plist"];
	
	if (prefs){
		
		if ([prefs objectForKey:@"isRedditEnabled"] != nil){
			isRedditEnabled = [[prefs objectForKey:@"isRedditEnabled"] boolValue];
		} else {
			isRedditEnabled = YES;
		}
		
		if ([prefs objectForKey:@"isTFDeletedOnly"] != nil) {
			isTFDeletedOnly = [[prefs objectForKey:@"isTFDeletedOnly"] boolValue];
		} else {
			isTFDeletedOnly = YES;
		}
		
		if ([prefs objectForKey:@"requestTimeoutValue"] != nil){
			pushshiftRequestTimeoutValue = [[prefs objectForKey:@"requestTimeoutValue"] doubleValue];
		} else {
			pushshiftRequestTimeoutValue = 10;
		}
		
	} else {
		isRedditEnabled = YES;
		isTFDeletedOnly = YES;
		pushshiftRequestTimeoutValue = 10;
	}
}

static void prefsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
  loadPrefs();
}


%ctor{
	loadPrefs();
	
	NSString* processName = [[NSProcessInfo processInfo] processName];
	
	@try{
		NSArray *redditVersion = [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] componentsSeparatedByString:@"."];
		
		firstVersionPart = [redditVersion[0] intValue];
		secondVersionPart = [redditVersion[1] intValue];
	}
	@catch (NSException *exc){
		firstVersionPart = 2020;
		secondVersionPart = 0;
	}

	if ([processName isEqualToString:@"Reddit"]){
		if (isRedditEnabled) {

			CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, prefsChanged, CFSTR("com.lint.undelete.prefs.changed"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
			
			if (firstVersionPart == 4 || firstVersionPart == 2020){
				if (secondVersionPart <= 32 && firstVersionPart != 2020){
					%init(Reddit_v4_ios10);
				} else{
					%init(Reddit_v4_current);
				}	
			} else if (firstVersionPart == 3) {
				%init(Reddit_v3);
			}
		}
	}
}
