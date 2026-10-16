//
//  Table_ToolTests.m
//  Table ToolTests
//
//  Created by Andreas Aigner on 06.07.15.
//  Copyright (c) 2015 Egger Apps. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import "CSVReader.h"
#import "CSVConfiguration.h"
#import "CSVHeuristic.h"
#import "CSVWriter.h"
#import "Document.h"

@interface Table_ToolTests : XCTestCase {
    int count;
    CSVConfiguration *config;
}

@end

@interface Document (DataPreservationTests)
-(BOOL)reloadDataWithError:(NSError **)error;
@end

@interface NativeIntegrationTests : XCTestCase
@end

@implementation NativeIntegrationTests

- (void)testLiteralCellTextSurvivesReadWriteAcrossDialectsAndEncodings {
    NSArray *values = @[@"00123", @"000", @"-0007", @"+8860912345678", @"1.2300",
                        @"1e003", @"12345678901234567890123456789012345678901234567890",
                        @" 00123 ", @"2026-10-16", @"=SUM(A1:A2)", @"繁體中文",
                        @"a,b;\t\"quoted\"\\path", @"line1\r\nline2", @""];
    NSArray *encodings = @[@(NSUTF8StringEncoding), @(NSUTF16StringEncoding),
                           @(CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingBig5))];
    for (NSNumber *encoding in encodings) {
        for (NSString *separator in @[@",", @";", @"\t"]) {
            for (NSString *escape in @[@"\"", @"\\"]) {
                CSVConfiguration *config = [[CSVConfiguration alloc] init];
                config.encoding = encoding.unsignedIntegerValue;
                config.columnSeparator = separator;
                config.escapeCharacter = escape;
                NSMutableArray *order = [NSMutableArray array];
                for (NSUInteger i = 0; i < values.count; i++) [order addObject:@(i)];
                CSVWriter *writer = [[CSVWriter alloc] initWithDataArray:@[values] columnsOrder:order configuration:config];
                NSError *error = nil;
                NSData *encoded = [writer writeDataWithError:&error];
                XCTAssertNotNil(encoded);
                CSVReader *reader = [[CSVReader alloc] initWithData:encoded configuration:config];
                XCTAssertEqualObjects([reader readLineWithError:&error], values, @"%@ / %@ / %@", encoding, separator, escape);
                XCTAssertTrue(reader.atEnd);
                XCTAssertNil(error);
            }
        }
    }
}

- (void)testPastedTextKeepsLeadingZerosAndColumnMapping {
    CSVReader *reader = [[CSVReader alloc] initWithString:@"00123\t1.2300\t1e03\r\n0007\t+0002\t 004 " configuration:[[CSVConfiguration alloc] init]];
    XCTAssertEqualObjects(([reader readLineForPastingTo:@[@2, @0, @1] maxColumnIndex:3]), (@[@"1.2300", @"1e03", @"00123"]));
    XCTAssertEqualObjects(([reader readLineForPastingTo:@[@2, @0, @1] maxColumnIndex:3]), (@[@"+0002", @" 004 ", @"0007"]));
    XCTAssertTrue(reader.atEnd);
}

- (void)testWriterPreservesRaggedRowsAndDoesNotMutateInput {
    NSArray *rows = @[@[@"001", @"x", @""], @[@"002"], @[@""], @[@"003", @"", @""]];
    CSVConfiguration *config = [[CSVConfiguration alloc] init];
    CSVWriter *writer = [[CSVWriter alloc] initWithDataArray:rows columnsOrder:@[@0, @1, @2] configuration:config];
    NSError *error = nil;
    CSVReader *reader = [[CSVReader alloc] initWithData:[writer writeDataWithError:&error] configuration:config];
    for (NSArray *row in rows) XCTAssertEqualObjects([reader readLineWithError:&error], row);
    XCTAssertNil(error);
    XCTAssertEqualObjects(rows[1], (@[@"002"]));
}

- (void)testUnsafeUnquotedOutputAndUnrepresentableEncodingAreRejected {
    CSVConfiguration *config = [[CSVConfiguration alloc] init];
    config.quoteCharacter = @"";
    config.escapeCharacter = @"";
    for (NSString *unsafe in @[@"two,columns", @"two\nrows", @"two\rrows", @"two\u2028rows"]) {
        CSVWriter *writer = [[CSVWriter alloc] initWithDataArray:@[@[unsafe]] columnsOrder:@[@0] configuration:config];
        NSError *error = nil;
        XCTAssertNil([writer writeDataWithError:&error]);
        XCTAssertNotNil(error);
    }
    config.quoteCharacter = @"\"";
    config.escapeCharacter = @"\"";
    config.encoding = NSASCIIStringEncoding;
    CSVWriter *writer = [[CSVWriter alloc] initWithDataArray:@[@[@"繁體中文"]] columnsOrder:@[@0] configuration:config];
    XCTAssertNil([writer writeDataWithError:NULL]);
}

- (void)testDocumentLeadingZerosNoOpSaveEditingUndoAndReopen {
    NSString *source = @"ID,Amount,Note,LongNumber\r\n00123,1.2300,\"a,b\",12345678901234567890123456789012345678901234567890\r\n00007,1e003,\"line1\nline2\",+0002\r\n";
    NSData *sourceData = [source dataUsingEncoding:NSUTF8StringEncoding];
    NSURL *directory = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString]];
    NSError *error = nil;
    XCTAssertTrue([NSFileManager.defaultManager createDirectoryAtURL:directory withIntermediateDirectories:YES attributes:nil error:&error]);
    NSURL *input = [directory URLByAppendingPathComponent:@"LeadingZeros.csv"];
    XCTAssertTrue([sourceData writeToURL:input options:NSDataWritingAtomic error:&error]);
    Document *document = [[Document alloc] init];
    XCTAssertTrue([document readFromURL:input ofType:@"DocumentType" error:&error]);
    [document makeWindowControllers];
    XCTAssertNotNil(document.windowControllers.firstObject.window);
    XCTAssertTrue(document.csvConfig.firstRowAsHeader);
    NSArray *expected = @[@[@"00123", @"1.2300", @"a,b", @"12345678901234567890123456789012345678901234567890"],
                          @[@"00007", @"1e003", @"line1\nline2", @"+0002"]];
    XCTAssertEqualObjects(document.data, expected);
    XCTAssertEqualObjects([document dataOfType:@"DocumentType" error:&error], sourceData);
    [document.undoManager removeAllActions];
    [document.undoManager beginUndoGrouping];
    [document tableView:document.tableView setObjectValue:@"000009" forTableColumn:document.tableView.tableColumns[0] row:0];
    [document.undoManager endUndoGrouping];
    XCTAssertEqualObjects(document.data[0][0], @"000009");
    [document.undoManager undo];
    XCTAssertEqualObjects(document.data, expected);
    [document.undoManager redo];
    NSMutableArray *edited = [NSMutableArray arrayWithArray:expected];
    edited[0] = @[@"000009", @"1.2300", @"a,b", @"12345678901234567890123456789012345678901234567890"];
    NSURL *output = [directory URLByAppendingPathComponent:@"Edited.csv"];
    XCTAssertTrue([document writeToURL:output ofType:@"DocumentType" error:&error]);
    Document *reopened = [[Document alloc] init];
    XCTAssertTrue([reopened readFromURL:output ofType:@"DocumentType" error:&error]);
    [reopened makeWindowControllers];
    XCTAssertNotNil(reopened.windowControllers.firstObject.window);
    XCTAssertEqualObjects(reopened.data, edited);
    XCTAssertEqualObjects([NSData dataWithContentsOfURL:input], sourceData);
    XCTAssertNil(error);
    [document updateChangeCount:NSChangeCleared];
    [reopened updateChangeCount:NSChangeCleared];
    [document close];
    [reopened close];
}

- (void)testDocumentBOMEncodingsAndSaveBeforeWindowLoads {
    NSString *source = @"ID,Note\r\n00123,繁體中文\r\n00007,001.2300\r\n";
    for (NSNumber *encoding in @[@(NSUTF8StringEncoding), @(NSUTF16StringEncoding), @(CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingBig5))]) {
        NSMutableData *bytes = [NSMutableData data];
        if (encoding.unsignedIntegerValue == NSUTF8StringEncoding) [bytes appendBytes:"\xef\xbb\xbf" length:3];
        [bytes appendData:[source dataUsingEncoding:encoding.unsignedIntegerValue]];
        NSURL *url = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[NSUUID.UUID.UUIDString stringByAppendingString:@".csv"]]];
        NSError *error = nil;
        XCTAssertTrue([bytes writeToURL:url options:NSDataWritingAtomic error:&error]);
        Document *document = [[Document alloc] init];
        XCTAssertTrue([document readFromURL:url ofType:@"DocumentType" error:&error]);
        // Legacy single-byte encodings can be ambiguous: exercise explicit Big5 selection.
        if (encoding.unsignedIntegerValue == CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingBig5)) {
            document.csvConfig.encoding = encoding.unsignedIntegerValue;
            XCTAssertTrue([document reloadDataWithError:&error]);
        } else {
            XCTAssertEqualObjects([document dataOfType:@"DocumentType" error:&error], bytes);
        }
        [document makeWindowControllers];
        XCTAssertNotNil(document.windowControllers.firstObject.window);
        XCTAssertEqualObjects(document.data, (@[@[@"00123", @"繁體中文"], @[@"00007", @"001.2300"]]));
        [document tableView:document.tableView setObjectValue:@"000009" forTableColumn:document.tableView.tableColumns[0] row:0];
        NSData *edited = [document dataOfType:@"DocumentType" error:&error];
        XCTAssertNotNil(edited);
        CSVReader *reader = [[CSVReader alloc] initWithData:edited configuration:document.csvConfig];
        XCTAssertEqualObjects([reader readLineWithError:&error], (@[@"ID", @"Note"]));
        XCTAssertEqualObjects([reader readLineWithError:&error], (@[@"000009", @"繁體中文"]));
        XCTAssertEqualObjects([reader readLineWithError:&error], (@[@"00007", @"001.2300"]));
        if (encoding.unsignedIntegerValue == NSUTF8StringEncoding) XCTAssertEqual(memcmp(bytes.bytes, edited.bytes, 3), 0);
        XCTAssertNil(error);
        [document updateChangeCount:NSChangeCleared];
        [document close];
    }
}

- (void)testBlankRecordsAndTrailingEmptyFields {
    for (NSString *source in @[@"\n\n", @"001,,\n\n002,,\n", @"001,,\r\n\r\n002,,\r\n"]) {
        CSVConfiguration *configuration = [[CSVConfiguration alloc] init];
        configuration.quoteCharacter = @"";
        CSVReader *reader = [[CSVReader alloc] initWithString:source configuration:configuration];
        NSMutableArray *rows = [NSMutableArray array];
        while (!reader.atEnd) [rows addObject:[reader readLineWithError:NULL]];
        CSVWriter *writer = [[CSVWriter alloc] initWithDataArray:rows columnsOrder:@[@0, @1, @2] configuration:configuration];
        NSData *output = [writer writeDataWithError:NULL];
        reader = [[CSVReader alloc] initWithData:output configuration:configuration];
        for (NSArray *row in rows) XCTAssertEqualObjects([reader readLineWithError:NULL], row);
        XCTAssertTrue(reader.atEnd);
    }
}

- (void)testFailedDocumentSaveLeavesExistingFileUntouched {
    NSData *source = [@"ID,Note\n00123,original" dataUsingEncoding:NSUTF8StringEncoding];
    NSURL *url = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[NSUUID.UUID.UUIDString stringByAppendingString:@".csv"]]];
    NSError *error = nil;
    XCTAssertTrue([source writeToURL:url options:NSDataWritingAtomic error:&error]);
    Document *document = [[Document alloc] init];
    XCTAssertTrue([document readFromURL:url ofType:@"DocumentType" error:&error]);
    [document makeWindowControllers];
    XCTAssertNotNil(document.windowControllers.firstObject.window);
    [document tableView:document.tableView setObjectValue:@"two,columns" forTableColumn:document.tableView.tableColumns[1] row:0];
    document.csvConfig.quoteCharacter = @"";
    XCTAssertFalse([document writeToURL:url ofType:@"DocumentType" error:&error]);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects([NSData dataWithContentsOfURL:url], source);
    document.csvConfig.quoteCharacter = @"\"";
    document.csvConfig.encoding = NSASCIIStringEncoding;
    [document tableView:document.tableView setObjectValue:@"繁體中文" forTableColumn:document.tableView.tableColumns[1] row:0];
    error = nil;
    XCTAssertFalse([document writeToURL:url ofType:@"DocumentType" error:&error]);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects([NSData dataWithContentsOfURL:url], source);
    [document updateChangeCount:NSChangeCleared];
    [document close];
}

- (void)testReorderedColumnsPreserveLiteralValues {
    CSVConfiguration *configuration = [[CSVConfiguration alloc] init];
    NSArray *rows = @[@[@"00123", @"1.2300", @"+0002"]];
    CSVWriter *writer = [[CSVWriter alloc] initWithDataArray:rows columnsOrder:@[@2, @0, @1] configuration:configuration];
    CSVReader *reader = [[CSVReader alloc] initWithData:[writer writeDataWithError:NULL] configuration:configuration];
    XCTAssertEqualObjects([reader readLineWithError:NULL], (@[@"+0002", @"00123", @"1.2300"]));
    XCTAssertEqualObjects(rows[0], (@[@"00123", @"1.2300", @"+0002"]));
}

- (void)testBig5TraditionalChineseRoundTrip {
    CSVConfiguration *configuration = [[CSVConfiguration alloc] init];
    configuration.encoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingBig5);
    NSArray *rows = @[[NSMutableArray arrayWithArray:@[@"姓名", @"備註"]],
                      [NSMutableArray arrayWithArray:@[@"雷蒙", @"繁體中文，測試"]]];
    CSVWriter *writer = [[CSVWriter alloc] initWithDataArray:rows columnsOrder:@[@0, @1] configuration:configuration];
    NSError *error = nil;
    NSData *encoded = [writer writeDataWithError:&error];
    XCTAssertNotNil(encoded);
    XCTAssertNil(error);
    CSVReader *reader = [[CSVReader alloc] initWithData:encoded configuration:configuration];
    XCTAssertEqualObjects([reader readLineWithError:&error], rows[0]);
    XCTAssertEqualObjects([reader readLineWithError:&error], rows[1]);
    XCTAssertNil(error);
}

- (void)testTranslatedNoQuoteControlUsesStableConfiguration {
    for (NSString *nib in @[@"TTFormatViewController", @"TTFormatViewControllerAccessory"]) {
        TTFormatViewController *controller = [[TTFormatViewController alloc] initWithNibName:nib bundle:nil];
        XCTAssertNotNil(controller.view);
        controller.escapeControl.selectedSegment = 2;
        [controller updateConfiguration:nil];
        XCTAssertEqualObjects(controller.config.quoteCharacter, @"");
        XCTAssertEqualObjects(controller.config.escapeCharacter, @"");
        controller.escapeControl.selectedSegment = 1;
        [controller updateConfiguration:nil];
        XCTAssertEqualObjects(controller.config.quoteCharacter, @"\"");
        XCTAssertEqualObjects(controller.config.escapeCharacter, @"\\");
    }
}

- (void)testLocalizedDocumentEditingAndSaveRoundTrip {
    NSString *source = @"Name,Note,Count\nRaymond,\"繁體中文，English\",00042\n柚子,\"line one\nline two\",7";
    NSURL *directory = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString]];
    NSError *error = nil;
    XCTAssertTrue([NSFileManager.defaultManager createDirectoryAtURL:directory withIntermediateDirectories:YES attributes:nil error:&error]);
    NSURL *input = [directory URLByAppendingPathComponent:@"Sample.csv"];
    XCTAssertTrue([source writeToURL:input atomically:YES encoding:NSUTF8StringEncoding error:&error]);
    Document *document = [[Document alloc] init];
    XCTAssertTrue([document readFromURL:input ofType:@"DocumentType" error:&error]);
    [document makeWindowControllers];
    NSWindow *window = document.windowControllers.firstObject.window;
    XCTAssertNotNil(window); // NSWindowController loads the document nib lazily.
    XCTAssertNotNil(document.tableView);
    XCTAssertEqual(document.tableView.numberOfColumns, 3);
    XCTAssertGreaterThanOrEqual(document.tableView.numberOfRows, 2);
    BOOL chinese = [NSBundle.mainBundle.preferredLocalizations.firstObject hasPrefix:@"zh"];
    XCTAssertEqualObjects(document.toolbarItemAddRow.label, chinese ? @"新增列" : @"Add Row");
    XCTAssertEqualObjects(document.toolbarItemAddColumn.label, chinese ? @"新增欄" : @"Add Column");
    TTFormatViewController *format = [document valueForKey:@"statusBarFormatViewController"];
    XCTAssertEqualObjects(format.useFirstRowAsHeaderCheckbox.title, chinese ? @"首列為標題" : @"Header");
    XCTAssertEqualObjects(NSLocalizedString(@"Could not read data", nil), chinese ? @"無法讀取資料" : @"Could not read data");
    NSUInteger row = document.csvConfig.firstRowAsHeader ? 0 : 1;
    [document tableView:document.tableView setObjectValue:@"測試完成，saved\nsecond line" forTableColumn:document.tableView.tableColumns[1] row:row];
    NSURL *output = [directory URLByAppendingPathComponent:@"Saved.csv"];
    XCTAssertTrue([document writeToURL:output ofType:@"DocumentType" error:&error]);
    Document *reopened = [[Document alloc] init];
    XCTAssertTrue([reopened readFromURL:output ofType:@"DocumentType" error:&error]);
    [reopened makeWindowControllers];
    XCTAssertNotNil(reopened.windowControllers.firstObject.window);
    XCTAssertEqualObjects(reopened.data, document.data);
    XCTAssertNil(error);

    window.title = @"Table Tool Native — Sample.csv";
    [window.contentView layoutSubtreeIfNeeded];
    NSView *view = window.contentView.superview;
    NSBitmapImageRep *bitmap = [view bitmapImageRepForCachingDisplayInRect:view.bounds];
    [view cacheDisplayInRect:view.bounds toBitmapImageRep:bitmap];
    NSData *png = [bitmap representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
    XCTAssertGreaterThan(png.length, 1000);
    XCTAttachment *attachment = [XCTAttachment attachmentWithData:png uniformTypeIdentifier:@"public.png"];
    attachment.name = chinese ? @"document-zh-Hant" : @"document-en";
    attachment.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:attachment];
    [document updateChangeCount:NSChangeCleared];
    [reopened updateChangeCount:NSChangeCleared];
    [document close];
    [reopened close];
}

@end

@implementation Table_ToolTests

- (void)setUp {
    [super setUp];
    count = 0;
    config = [[CSVConfiguration alloc]init];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testReadCommaSeparatedCSVFile {
    NSURL *testFileURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"Reading Test Documents/comma-separated" withExtension:@"csv"];
    NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileURL];
    config.quoteCharacter = @"";
    CSVReader *reader = [[CSVReader alloc]initWithData:testData configuration:config];
    while(!reader.isAtEnd){
        NSArray *line = [reader readLineWithError:NULL];
        XCTAssertNotNil(line, "CSVReader should return object.");
        count++;
        XCTAssertEqual(line.count, 3, "Read line should have 3 objects.");
        if(count == 3){
            for(int i=0;i<3;i++){
                XCTAssertTrue([line[i] isKindOfClass:[NSString class]], "Numeric-looking cells must retain literal text.");
                XCTAssertTrue([config isNumericText:line[i]]);
            }
        }
    }
    XCTAssertEqual(count, 3, "CSVReader should have read 3 lines.");
    XCTAssert(YES, @"Pass");
}

- (void)testReadSemicolonSeparatedCSVFile {
    NSURL *testFileURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"Reading Test Documents/semicolon-separated" withExtension:@"csv"];
    NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileURL];
    config.columnSeparator = @";";
    config.decimalMark = @",";
    config.quoteCharacter = @"";
    CSVReader *reader = [[CSVReader alloc]initWithData:testData configuration:config];
    while(!reader.isAtEnd){
        NSArray *line = [reader readLineWithError:NULL];
        XCTAssertNotNil(line, "CSVReader should return object.");
        count++;
        XCTAssertEqual(line.count, 3, "Read line should have 3 objects.");
        if(count == 3){
            for(int i=0;i<3;i++){
                XCTAssertTrue([line[i] isKindOfClass:[NSString class]], "Numeric-looking cells must retain literal text.");
                XCTAssertTrue([config isNumericText:line[i]]);
            }
        }
    }
    XCTAssertEqual(count, 3, "CSVReader should have read 3 lines.");
    XCTAssert(YES, @"Pass");
}

- (void)testReadQuotedCommaSeparatedCSVFile {
    NSURL *testFileURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"Reading Test Documents/comma-separated-quote" withExtension:@"csv"];
    NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileURL];
    config.decimalMark = @",";
    CSVReader *reader = [[CSVReader alloc]initWithData:testData configuration:config];
    while(!reader.isAtEnd){
        NSArray *line = [reader readLineWithError:NULL];
        XCTAssertNotNil(line, "CSVReader should return object.");
        count++;
        XCTAssertEqual(line.count, 3, "Read line should have 3 objects.");
        if(count == 2 || count == 3){
            for(int i=0;i<3;i++){
                XCTAssertTrue([line[i] isKindOfClass:[NSString class]], @"Numeric-looking cells must retain literal text.");
                XCTAssertTrue([config isNumericText:line[i]]);
            }
        }
    }
    XCTAssertEqual(count, 3, "CSVReader should have read 3 lines.");
    XCTAssert(YES, @"Pass");
}

- (void)testReadQuotedCSVFileWithQuoteEscape {
    NSURL *testFileURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"Reading Test Documents/quote-quote-escape" withExtension:@"csv"];
    NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileURL];
    CSVReader *reader = [[CSVReader alloc]initWithData:testData configuration:config];
    while(!reader.isAtEnd){
        NSArray *line = [reader readLineWithError:NULL];
        XCTAssertNotNil(line, "CSVReader should return object.");
        count++;
        XCTAssertEqual(line.count, 2, "Read line should have 2 objects.");
        if(count == 2){
            XCTAssertTrue([line[0] isKindOfClass:[NSString class]], @"Cell remains text.");
            XCTAssertTrue([config isNumericText:line[0]]);
            XCTAssertFalse([line[1] isKindOfClass:[NSDecimalNumber class]], @"Second object should not be decimal number.");
        }
    }
    XCTAssertEqual(count, 2, "CSVReader should have read 2 lines.");
    XCTAssert(YES, @"Pass");
}

- (void)testReadQuotedCSVFileWithBackslashEscape {
    NSURL *testFileURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"Reading Test Documents/quote-backslash-escape" withExtension:@"csv"];
    NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileURL];
    config.escapeCharacter = @"\\";
    CSVReader *reader = [[CSVReader alloc]initWithData:testData configuration:config];
    while(!reader.isAtEnd){
        NSArray *line = [reader readLineWithError:NULL];
        XCTAssertNotNil(line, "CSVReader should return object.");
        count++;
        XCTAssertEqual(line.count, 2, "Read line should have 2 objects.");
        if(count == 2){
            XCTAssertTrue([line[0] isKindOfClass:[NSString class]], @"Cell remains text.");
            XCTAssertTrue([config isNumericText:line[0]]);
            XCTAssertFalse([line[1] isKindOfClass:[NSDecimalNumber class]], @"Second object should not be decimal number.");
        }
    }
    XCTAssertEqual(count, 2, "CSVReader should have read 2 lines.");
    XCTAssert(YES, @"Pass");
}

- (void)testReadCSVFileWithInvalidEncoding_ShouldGetErrorCode1 {
    NSURL *testFileURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"Reading Test Documents/invalid-encoding" withExtension:@"csv"];
    NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileURL];
    CSVReader *reader = [[CSVReader alloc]initWithData:testData configuration:config];
    NSError *error = nil;
    while(!reader.isAtEnd){
        NSArray *line = [reader readLineWithError:&error];
        if(error) break;
        XCTAssertNotNil(line, "CSVReader should return object.");
    }
    XCTAssertEqual(error.code, 1, "Returned wrong error code");
    XCTAssert(YES, @"Pass");
}

- (void)testReadCSVFileWithMissingQuoteAtEnd_ShouldGetErrorCode2 {
    NSURL *testFileURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"Reading Test Documents/missing-quote-atEnd" withExtension:@"csv"];
    NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileURL];
    CSVReader *reader = [[CSVReader alloc]initWithData:testData configuration:config];
    NSError *error = nil;
    while(!reader.isAtEnd){
        NSArray *line = [reader readLineWithError:&error];
        if(error) break;
        XCTAssertNil(line, "CSVReader should not return object.");
    }
    XCTAssertEqual(error.code, 2, "Returned wrong error code");
    XCTAssert(YES, @"Pass");
}

- (void)testReadCSVFileWithMissingBackslashBeforeValue_ShouldGetErrorCode2 {
    NSURL *testFileURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"Reading Test Documents/missing-backslash-beforeValue" withExtension:@"csv"];
    NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileURL];
    config.escapeCharacter = @"\\";
    CSVReader *reader = [[CSVReader alloc]initWithData:testData configuration:config];
    NSError *error = nil;
    while(!reader.isAtEnd){
        NSArray *line = [reader readLineWithError:&error];
        if(error) break;
        XCTAssertNil(line, "CSVReader should not return object.");
    }
    XCTAssertEqual(error.code, 2, "Returned wrong error code");
    XCTAssert(YES, @"Pass");
}

- (void)testReadCSVFileWithMissingBackslashAfterValue_ShouldGetErrorCode2 {
    NSURL *testFileURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"Reading Test Documents/missing-backslash-afterValue" withExtension:@"csv"];
    NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileURL];
    config.escapeCharacter = @"\\";
    CSVReader *reader = [[CSVReader alloc]initWithData:testData configuration:config];
    NSError *error = nil;
    while(!reader.isAtEnd){
        NSArray *line = [reader readLineWithError:&error];
        if(error) break;
        XCTAssertNil(line, "CSVReader should not return object.");
    }
    XCTAssertEqual(error.code, 2, "Returned wrong error code");
    XCTAssert(YES, @"Pass");
}

- (void)testReadCSVFileWithMissingValueForBackslashInquote_ShouldGetErrorCode2 {
    NSURL *testFileURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"Reading Test Documents/missing-value-for-backslash-inquote" withExtension:@"csv"];
    NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileURL];
    config.escapeCharacter = @"\\";
    CSVReader *reader = [[CSVReader alloc]initWithData:testData configuration:config];
    NSError *error = nil;
    while(!reader.isAtEnd){
        NSArray *line = [reader readLineWithError:&error];
        if(error) break;
        XCTAssertNil(line, "CSVReader should not return object.");
    }
    XCTAssertEqual(error.code, 2, "Returned wrong error code");
    XCTAssert(YES, @"Pass");
}

- (void)testReadCSVFileWithMissingValueForeBackslashBeforeValue_ShouldGetErrorCode2 {
    NSURL *testFileURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"Reading Test Documents/missing-value-for-backslash" withExtension:@"csv"];
    NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileURL];
    config.escapeCharacter = @"\\";
    CSVReader *reader = [[CSVReader alloc]initWithData:testData configuration:config];
    NSError *error = nil;
    while(!reader.isAtEnd){
        NSArray *line = [reader readLineWithError:&error];
        if(error) break;
        XCTAssertNil(line, "CSVReader should not return object.");
    }
    XCTAssertEqual(error.code, 2, "Returned wrong error code");
    XCTAssert(YES, @"Pass");
}

- (void)testReadCSVFileWithQuoteInUnquotedValue_ShouldGetErrorCode3 {
    NSURL *testFileURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"Reading Test Documents/quote-in-unquoted-value" withExtension:@"csv"];
    NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileURL];
    CSVReader *reader = [[CSVReader alloc]initWithData:testData configuration:config];
    NSError *error = nil;
    while(!reader.isAtEnd){
        NSArray *line = [reader readLineWithError:&error];
        if(error) break;
        XCTAssertNil(line, "CSVReader should not return object.");
    }
    XCTAssertEqual(error.code, 3, "Returned wrong error code");
    XCTAssert(YES, @"Pass");
}

- (void)testReadCSVFileWithBlankLines {
	NSURL *testFileURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"Reading Test Documents/blank-lines" withExtension:@"csv"];
	NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileURL];
	CSVReader *reader = [[CSVReader alloc]initWithData:testData configuration:config];
	NSError *error = nil;
	NSUInteger numLines = 0;
	while([reader readLineWithError:&error]) {
		numLines++;
	}
	XCTAssertEqual(numLines, 6, "File should contain 6 rows.");
}



- (void)testHeuristicError1 {
    NSURL *testFileUrl = [[NSBundle bundleForClass:[self class]] URLForResource:@"Heuristic Test Documents/heuristic-comma-separated-people-1" withExtension:@"csv"];
    NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileUrl];
    CSVHeuristic *heuristic = [[CSVHeuristic alloc] initWithData:testData];
    config = [heuristic calculatePossibleFormat];
    XCTAssertEqual([config.columnSeparator characterAtIndex:0], ',', "Column Separator should be ','.");
    XCTAssertEqual([config.decimalMark characterAtIndex:0], '.', "Decimal Mark should be '.'.");
    XCTAssertEqual([config.quoteCharacter characterAtIndex:0], '\"', "Quote should be enabled.");
    XCTAssertTrue(config.firstRowAsHeader, "First row should be header.");
    XCTAssertEqual([config.escapeCharacter characterAtIndex:0], '\"', "Escape character should be '\"'.");
}

- (void)testHeuristicError2 {
    NSURL *testFileUrl = [[NSBundle bundleForClass:[self class]] URLForResource:@"Heuristic Test Documents/heuristic-comma-separated-people-2" withExtension:@"csv"];
    NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileUrl];
    CSVHeuristic *heuristic = [[CSVHeuristic alloc] initWithData:testData];
    config = [heuristic calculatePossibleFormat];
    XCTAssertEqual([config.columnSeparator characterAtIndex:0], ',', "Column Separator should be ','.");
    XCTAssertEqual([config.decimalMark characterAtIndex:0], '.', "Decimal Mark should be '.'.");
    XCTAssertTrue(config.firstRowAsHeader, "First row should be header.");
    XCTAssertEqual([config.escapeCharacter characterAtIndex:0], '\"', "Escape character should be '\"'.");
}

- (void)testHeuristicError3 {
    NSURL *testFileUrl = [[NSBundle bundleForClass:[self class]] URLForResource:@"Heuristic Test Documents/heuristic-comma-separated-places" withExtension:@"csv"];
    NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileUrl];
    CSVHeuristic *heuristic = [[CSVHeuristic alloc] initWithData:testData];
    config = [heuristic calculatePossibleFormat];
    XCTAssertEqual([config.columnSeparator characterAtIndex:0], ',', "Column Separator should be ','.");
    XCTAssertEqual([config.decimalMark characterAtIndex:0], '.', "Decimal Mark should be '.'.");
    XCTAssert([config.quoteCharacter isEqual:@"\""], "Quote should be enabled.");
    XCTAssertTrue(config.firstRowAsHeader, "First row should be header.");
    XCTAssertEqual([config.escapeCharacter characterAtIndex:0], '\"', "Escape character should be '\"'.");
}

//For config descriptions see CSVHeuristic.m
- (void)testHeuristicConfig1 {
    NSURL *testFileUrl = [[NSBundle bundleForClass:[self class]] URLForResource:@"Heuristic Test Documents/heuristic-config1" withExtension:@"csv"];
    NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileUrl];
    CSVHeuristic *heuristic = [[CSVHeuristic alloc] initWithData:testData];
    config = [heuristic calculatePossibleFormat];
    XCTAssertEqual([config.columnSeparator characterAtIndex:0], ',', "Column Separator should be ','.");
    XCTAssertEqual([config.decimalMark characterAtIndex:0], '.', "Decimal Mark should be '.'.");
    XCTAssertEqual([config.quoteCharacter characterAtIndex:0], '\"', "Quote should be enabled.");
    XCTAssertTrue(config.firstRowAsHeader, "First row should be header.");
    XCTAssertEqual([config.escapeCharacter characterAtIndex:0], '\"', "Escape character should be '\"'.");
}

//For config descriptions see CSVHeuristic.m
- (void)testHeuristicConfig2 {
    NSURL *testFileUrl = [[NSBundle bundleForClass:[self class]] URLForResource:@"Heuristic Test Documents/heuristic-config2" withExtension:@"csv"];
    NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileUrl];
    CSVHeuristic *heuristic = [[CSVHeuristic alloc] initWithData:testData];
    config = [heuristic calculatePossibleFormat];
    XCTAssertEqual([config.columnSeparator characterAtIndex:0], ';', "Column Separator should be ';'.");
    XCTAssertEqual([config.decimalMark characterAtIndex:0], ',', "Decimal Mark should be ','.");
    XCTAssertEqual([config.quoteCharacter characterAtIndex:0], '\"', "Quote should be enabled.");
    XCTAssertTrue(config.firstRowAsHeader, "First row should be header.");
    XCTAssertEqual([config.escapeCharacter characterAtIndex:0], '\"', "Escape character should be '\"'.");
}

//For config descriptions see CSVHeuristic.m
- (void)testHeuristicConfig3 {
    NSURL *testFileUrl = [[NSBundle bundleForClass:[self class]] URLForResource:@"Heuristic Test Documents/heuristic-config3" withExtension:@"csv"];
    NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileUrl];
    CSVHeuristic *heuristic = [[CSVHeuristic alloc] initWithData:testData];
    config = [heuristic calculatePossibleFormat];
    XCTAssertEqual([config.columnSeparator characterAtIndex:0], '\t', "Column Separator should be '\t'.");
    XCTAssertEqual([config.decimalMark characterAtIndex:0], '.', "Decimal Mark should be '.'.");
    XCTAssertEqual([config.quoteCharacter characterAtIndex:0], '\"', "Quote should be enabled.");
    XCTAssertTrue(config.firstRowAsHeader, "First row should be header.");
    XCTAssertEqual([config.escapeCharacter characterAtIndex:0], '\"', "Escape character should be '\"'.");
}

//For config descriptions see CSVHeuristic.m
- (void)testHeuristicConfig4 {
    NSURL *testFileUrl = [[NSBundle bundleForClass:[self class]] URLForResource:@"Heuristic Test Documents/heuristic-config4" withExtension:@"csv"];
    NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileUrl];
    CSVHeuristic *heuristic = [[CSVHeuristic alloc] initWithData:testData];
    config = [heuristic calculatePossibleFormat];
    XCTAssertEqual([config.columnSeparator characterAtIndex:0], '\t', "Column Separator should be '\t'.");
    XCTAssertEqual([config.decimalMark characterAtIndex:0], ',', "Decimal Mark should be ','.");
    XCTAssertEqual([config.quoteCharacter characterAtIndex:0], '\"', "Quote should be enabled.");
    XCTAssertTrue(config.firstRowAsHeader, "First row should be header.");
    XCTAssertEqual([config.escapeCharacter characterAtIndex:0], '\"', "Escape character should be '\"'.");
}

//For config descriptions see CSVHeuristic.m
- (void)testHeuristicConfig5 {
    NSURL *testFileUrl = [[NSBundle bundleForClass:[self class]] URLForResource:@"Heuristic Test Documents/heuristic-config5" withExtension:@"csv"];
    NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileUrl];
    CSVHeuristic *heuristic = [[CSVHeuristic alloc] initWithData:testData];
    config = [heuristic calculatePossibleFormat];
    XCTAssertEqual([config.columnSeparator characterAtIndex:0], ';', "Column Separator should be ';'.");
    XCTAssertEqual([config.decimalMark characterAtIndex:0], ',', "Decimal Mark should be ','.");
    XCTAssertEqual([config.quoteCharacter characterAtIndex:0], '\"', "Quote should be enabled.");
    XCTAssertTrue(config.firstRowAsHeader, "First row should be header.");
    XCTAssertEqual([config.escapeCharacter characterAtIndex:0], '\\', "Escape character should be '\\'.");
}

//For config descriptions see CSVHeuristic.m
- (void)testHeuristicConfig6 {
    NSURL *testFileUrl = [[NSBundle bundleForClass:[self class]] URLForResource:@"Heuristic Test Documents/heuristic-config6" withExtension:@"csv"];
    NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileUrl];
    CSVHeuristic *heuristic = [[CSVHeuristic alloc] initWithData:testData];
    config = [heuristic calculatePossibleFormat];
    XCTAssertEqual([config.columnSeparator characterAtIndex:0], ',', "Column Separator should be ','.");
    XCTAssertEqual([config.decimalMark characterAtIndex:0], '.', "Decimal Mark should be '.'.");
    XCTAssertTrue([config.quoteCharacter isEqualToString:@""], "Quote should be disabled.");
    XCTAssertTrue(config.firstRowAsHeader, "First row should be header.");
    XCTAssertEqual([config.escapeCharacter characterAtIndex:0], '\"', "Escape character should be '\"'.");
}

//For config descriptions see CSVHeuristic.m
- (void)testHeuristicConfig7 {
    NSURL *testFileUrl = [[NSBundle bundleForClass:[self class]] URLForResource:@"Heuristic Test Documents/heuristic-config7" withExtension:@"csv"];
    NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileUrl];
    CSVHeuristic *heuristic = [[CSVHeuristic alloc] initWithData:testData];
    config = [heuristic calculatePossibleFormat];
    XCTAssertEqual([config.columnSeparator characterAtIndex:0], ';', "Column Separator should be ';'.");
    XCTAssertEqual([config.decimalMark characterAtIndex:0], ',', "Decimal Mark should be ','.");
    XCTAssertTrue([config.quoteCharacter isEqualToString:@""], "Quote should be disabled.");
    XCTAssertTrue(config.firstRowAsHeader, "First row should be header.");
    XCTAssertEqual([config.escapeCharacter characterAtIndex:0], '\"', "Escape character should be '\"'.");
}

//For config descriptions see CSVHeuristic.m
- (void)testHeuristicConfig8 {
    NSURL *testFileUrl = [[NSBundle bundleForClass:[self class]] URLForResource:@"Heuristic Test Documents/heuristic-config8" withExtension:@"csv"];
    NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileUrl];
    CSVHeuristic *heuristic = [[CSVHeuristic alloc] initWithData:testData];
    config = [heuristic calculatePossibleFormat];
    XCTAssertEqual([config.columnSeparator characterAtIndex:0], '\t', "Column Separator should be '\t'.");
    XCTAssertEqual([config.decimalMark characterAtIndex:0], '.', "Decimal Mark should be '.'.");
    XCTAssertTrue([config.quoteCharacter isEqualToString:@""], "Quote should be disabled.");
    XCTAssertTrue(config.firstRowAsHeader, "First row should be header.");
    XCTAssertEqual([config.escapeCharacter characterAtIndex:0], '\"', "Escape character should be '\"'.");
}

//For config descriptions see CSVHeuristic.m
- (void)testHeuristicConfig9 {
    NSURL *testFileUrl = [[NSBundle bundleForClass:[self class]] URLForResource:@"Heuristic Test Documents/heuristic-config9" withExtension:@"csv"];
    NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileUrl];
    CSVHeuristic *heuristic = [[CSVHeuristic alloc] initWithData:testData];
    config = [heuristic calculatePossibleFormat];
    XCTAssertEqual([config.columnSeparator characterAtIndex:0], '\t', "Column Separator should be '\t'.");
    XCTAssertEqual([config.decimalMark characterAtIndex:0], ',', "Decimal Mark should be ','.");
    XCTAssertTrue([config.quoteCharacter isEqualToString:@""], "Quote should be disabled.");
    XCTAssertTrue(config.firstRowAsHeader, "First row should be header.");
    XCTAssertEqual([config.escapeCharacter characterAtIndex:0], '\"', "Escape character should be '\"'.");
}

//For config descriptions see CSVHeuristic.m
- (void)testHeuristicConfig10 {
    NSURL *testFileUrl = [[NSBundle bundleForClass:[self class]] URLForResource:@"Heuristic Test Documents/heuristic-config10" withExtension:@"csv"];
    NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileUrl];
    CSVHeuristic *heuristic = [[CSVHeuristic alloc] initWithData:testData];
    config = [heuristic calculatePossibleFormat];
    XCTAssertEqual([config.columnSeparator characterAtIndex:0], ',', "Column Separator should be ','.");
    XCTAssertEqual([config.decimalMark characterAtIndex:0], '.', "Decimal Mark should be '.'.");
    XCTAssertEqual([config.quoteCharacter characterAtIndex:0], '\"', "Quote should be enabled.");
    XCTAssertTrue(config.firstRowAsHeader, "First row should be header.");
    XCTAssertEqual([config.escapeCharacter characterAtIndex:0], '\\', "Escape character should be '\\'.");
}

//For config descriptions see CSVHeuristic.m
- (void)testHeuristicConfig11 {
    NSURL *testFileUrl = [[NSBundle bundleForClass:[self class]] URLForResource:@"Heuristic Test Documents/heuristic-config11" withExtension:@"csv"];
    NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileUrl];
    CSVHeuristic *heuristic = [[CSVHeuristic alloc] initWithData:testData];
    config = [heuristic calculatePossibleFormat];
    XCTAssertEqual([config.columnSeparator characterAtIndex:0], ',', "Column Separator should be ','.");
    XCTAssertEqual([config.decimalMark characterAtIndex:0], ',', "Decimal Mark should be ','.");
    XCTAssertEqual([config.quoteCharacter characterAtIndex:0], '\"', "Quote should be enabled.");
    XCTAssertTrue(config.firstRowAsHeader, "First row should be header.");
    XCTAssertEqual([config.escapeCharacter characterAtIndex:0], '\"', "Escape character should be '\"'.");
}

- (void)testHeuristicNoHeaderBecauseOfNumber {
    NSURL *testFileUrl = [[NSBundle bundleForClass:[self class]] URLForResource:@"Heuristic Test Documents/heuristic-first-row-with-number" withExtension:@"csv"];
    NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileUrl];
    CSVHeuristic *heuristic = [[CSVHeuristic alloc] initWithData:testData];
    config = [heuristic calculatePossibleFormat];
    XCTAssertFalse(config.firstRowAsHeader, "First row should not be header");
}

- (void)testHeuristicNoHeaderBecauseOfShorterLength {
    NSURL *testFileUrl = [[NSBundle bundleForClass:[self class]] URLForResource:@"Heuristic Test Documents/heuristic-first-row-one-row-shorter" withExtension:@"csv"];
    NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileUrl];
    CSVHeuristic *heuristic = [[CSVHeuristic alloc] initWithData:testData];
    config = [heuristic calculatePossibleFormat];
    XCTAssertFalse(config.firstRowAsHeader, "First row should not be header");
}

- (void)testHeuristicNoHeaderBecauseOfLongerLength {
    NSURL *testFileUrl = [[NSBundle bundleForClass:[self class]] URLForResource:@"Heuristic Test Documents/heuristic-first-row-longer" withExtension:@"csv"];
    NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileUrl];
    CSVHeuristic *heuristic = [[CSVHeuristic alloc] initWithData:testData];
    config = [heuristic calculatePossibleFormat];
    XCTAssertFalse(config.firstRowAsHeader, "First row should not be header");
}

- (void)testHeuristicChangeEncodingToWestern {
    NSURL *testFileUrl = [[NSBundle bundleForClass:[self class]] URLForResource:@"Heuristic Test Documents/heuristic-no-utf-encoding" withExtension:@"csv"];
    NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileUrl];
    CSVHeuristic *heuristic = [[CSVHeuristic alloc] initWithData:testData];
    config = [heuristic calculatePossibleFormat];
    XCTAssertEqual(config.encoding, NSWindowsCP1252StringEncoding, "Encoding should be Western");
}

- (void)testHeuristicGBK {
	NSURL *testFileUrl = [[NSBundle bundleForClass:[self class]] URLForResource:@"Heuristic Test Documents/heuristic-gbk" withExtension:@"csv"];
	NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileUrl];
	CSVHeuristic *heuristic = [[CSVHeuristic alloc] initWithData:testData];
	heuristic.preferChineseEncoding = YES;
	config = [heuristic calculatePossibleFormat];
	XCTAssertEqual(config.encoding, CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000), "Encoding should be GBK");
}

- (void)testHeuristicIssue4Sample {
	NSURL *testFileUrl = [[NSBundle bundleForClass:[self class]] URLForResource:@"Heuristic Test Documents/issue-4-sample" withExtension:@"csv"];
	NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileUrl];
	CSVHeuristic *heuristic = [[CSVHeuristic alloc] initWithData:testData];
	config = [heuristic calculatePossibleFormat];
	XCTAssertEqual(config.encoding, NSMacOSRomanStringEncoding);
	XCTAssertEqualObjects(config.columnSeparator, @"\t");
	XCTAssertTrue(config.firstRowAsHeader);
}

- (void)testPerformanceReaderUnquotedValues {
    NSURL *testFileURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"test-doc-unquoted" withExtension:@"csv"];
    config.quoteCharacter = @"";
    [self measureBlock:^{
        NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileURL];
        CSVReader *reader = [[CSVReader alloc]initWithData:testData configuration:config];
        while(!reader.isAtEnd){
            NSArray *line = [reader readLineWithError:NULL];
            XCTAssertEqual(line.count, 12);
            XCTAssertNotNil(line, "CSVReader should return object.");
            count++;
        }
        XCTAssertEqual(count, 987, "Should have read 987 lines.");
        count = 0;
    }];
}

- (void)testPerformanceReaderQuotedValues {
    NSURL *testFileURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"test-doc-quoted" withExtension:@"csv"];
    [self measureBlock:^{
        NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileURL];
        CSVReader *reader = [[CSVReader alloc]initWithData:testData configuration:config];
        while(!reader.isAtEnd){
            NSArray *line = [reader readLineWithError:NULL];
            XCTAssertEqual(line.count, 11);
            XCTAssertNotNil(line, "CSVReader should return object.");
            count++;
        }
        XCTAssertEqual(count, 1002, "Should have read 1002 lines.");
        count = 0;
    }];
}

- (void)testPerformanceHeuristic {
    NSURL *testFileURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"test-doc-quoted" withExtension:@"csv"];
    [self measureBlock:^{
        for(int i = 0;i < 10; i++){
            NSData *testData = [[NSData alloc] initWithContentsOfURL:testFileURL];
            CSVHeuristic *heuristic = [[CSVHeuristic alloc]initWithData:testData];
            config = [heuristic calculatePossibleFormat];
            XCTAssertEqual([config.columnSeparator characterAtIndex:0], ',', "Column Separator should be ','.");
            XCTAssertEqual([config.decimalMark characterAtIndex:0], ',', "Decimal Mark should be ','.");
            XCTAssertEqual([config.quoteCharacter characterAtIndex:0], '\"', "Quote should be enabled.");
            XCTAssertEqual(config.firstRowAsHeader, YES, "First row should be header.");
            XCTAssertEqual([config.escapeCharacter characterAtIndex:0], '\"', "Escape character should be '\"'.");
            config = nil;
        }
    }];
    
}

@end
