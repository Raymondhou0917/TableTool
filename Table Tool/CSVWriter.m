//
//  CSVWriter.m
//  Table Tool
//
//  Created by Andreas Aigner on 10.07.15.
//  Copyright (c) 2015 Egger Apps. All rights reserved.
//

#import "CSVWriter.h"

@implementation CSVWriter {
    NSCharacterSet *quoteOrColumnSeparator;
    NSString *errorCode4;
}


-(instancetype)initWithDataArray:(NSArray *)dataArray columnsOrder:(NSArray *)columnsOrder configuration:(CSVConfiguration *)config{
    self = [super init];
    if(self) {
        _dataArray = dataArray;
        _config = config.copy;
        _columnsOrder = columnsOrder;
        errorCode4 = NSLocalizedString(@"Try choosing a different encoding to export the data.", nil);
    }
    return self;
}

-(NSString *)writeString {
    NSMutableArray *records = [NSMutableArray array];
    for (NSArray *row in _dataArray) {
        // Missing trailing cells stay missing. Do not pad or mutate the document while saving.
        NSUInteger width = 0;
        for (NSUInteger i = 0; i < _columnsOrder.count; i++) {
            if ([_columnsOrder[i] integerValue] < row.count) width = i + 1;
        }
        NSMutableArray *cells = [NSMutableArray array];
        for (NSUInteger i = 0; i < width; i++) {
            NSUInteger index = [_columnsOrder[i] integerValue];
            NSString *cell = index < row.count ? row[index] : @"";
            if ([_config.quoteCharacter isEqualToString:@"\""]) {
                NSMutableString *escaped = cell.mutableCopy;
                if (![_config.escapeCharacter isEqualToString:_config.quoteCharacter]) {
                    [escaped replaceOccurrencesOfString:_config.escapeCharacter withString:[_config.escapeCharacter stringByAppendingString:_config.escapeCharacter] options:0 range:NSMakeRange(0, escaped.length)];
                }
                [escaped replaceOccurrencesOfString:@"\"" withString:[_config.escapeCharacter stringByAppendingString:@"\""] options:0 range:NSMakeRange(0, escaped.length)];
                [cells addObject:[NSString stringWithFormat:@"\"%@\"", escaped]];
            } else {
                // Without quoting, a separator or newline would silently create new cells/rows.
                NSMutableCharacterSet *newlines = NSCharacterSet.newlineCharacterSet.mutableCopy;
                [newlines removeCharactersInString:@"\x0b\x0c"];
                if ([cell containsString:_config.columnSeparator] || [cell rangeOfCharacterFromSet:newlines].location != NSNotFound) return nil;
                [cells addObject:cell];
            }
        }
        [records addObject:[cells componentsJoinedByString:_config.columnSeparator]];
    }
    NSMutableString *result = [[records componentsJoinedByString:_config.lineEnding] mutableCopy];
    // A final one-cell empty row needs a terminator to distinguish it from EOF.
    BOOL finalEmptyRecord = records.count && [records.lastObject length] == 0;
    if (records.count && (_config.trailingNewline || finalEmptyRecord)) [result appendString:_config.lineEnding];
    return result;
}

-(NSData *)writeDataWithError:(NSError *__autoreleasing *)outError {
    NSString *dataString = [self writeString];
    if (!dataString) {
        if (outError) *outError = [NSError errorWithDomain:@"at.eggerapps.Table-Tool" code:6 userInfo:@{
            NSLocalizedDescriptionKey:NSLocalizedString(@"Could not write data", nil),
            NSLocalizedRecoverySuggestionErrorKey:NSLocalizedString(@"Enable quotes before saving cells containing separators or newlines.", nil)}];
        return nil;
    }
    NSData *encoded = [dataString dataUsingEncoding:_config.encoding allowLossyConversion:NO];
    if (!encoded) {
        if (outError) *outError = [NSError errorWithDomain:@"at.eggerapps.Table-Tool" code:4 userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"Could not write data", nil), NSLocalizedRecoverySuggestionErrorKey:errorCode4}];
        return nil;
    }
    if (_config.utf8BOM && _config.encoding == NSUTF8StringEncoding) {
        NSMutableData *withBOM = [NSMutableData dataWithBytes:"\xef\xbb\xbf" length:3];
        [withBOM appendData:encoded];
        return withBOM;
    }
    return encoded;
}

@end
