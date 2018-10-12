//
//  ViewController.m
//  SpeechRecognitionSystem
//
//  Created by SunLu on 2018/8/15.
//  Copyright © 2018年 Sl. All rights reserved.
//

#import "ViewController.h"
#import <Speech/Speech.h>
#import <Masonry.h>
API_AVAILABLE(ios(10.0))
@interface ViewController ()
@property(nonatomic, strong) SFSpeechRecognizer *speechRecognizer;
@property(nonatomic, strong) SFSpeechAudioBufferRecognitionRequest *recognitionRequest;
@property(nonatomic, strong) AVAudioEngine *audioEngine;

@property(nonatomic, strong) UITextView *textView;
@property(nonatomic, strong) UIButton *speechButton;
@property(nonatomic, strong) UIButton *recognitionButton;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor greenColor];
    [self.navigationController setNavigationBarHidden:YES];
    
    if (@available(iOS 10.0, *)) {
        [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
             NSLog(@"status %@", status == SFSpeechRecognizerAuthorizationStatusAuthorized ? @"授权成功" : @"授权失败");
        }];
    } else {
        
    }
    
    self.textView = [[UITextView alloc] init];
    [self.view addSubview:self.textView];
    self.textView.font = [UIFont systemFontOfSize:15];
    self.textView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];
    self.textView.textColor = [UIColor whiteColor];
    [self.textView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(44);
        make.left.equalTo(self.view).offset(15);
        make.right.equalTo(self.view).offset(-15);
        make.height.equalTo(@168);
    }];
    
    self.speechButton = [[UIButton alloc] init];
    [self.view addSubview:self.speechButton];
    [self.speechButton setBackgroundColor:[UIColor blackColor]];
    [self.speechButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.speechButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.textView.mas_bottom).offset(20);
        make.left.right.equalTo(self.textView);
        make.height.equalTo(@45);
    }];
    [self.speechButton setTitle:@"Begin Speech" forState:UIControlStateNormal];
    [self.speechButton addTarget:self action:@selector(startRecording:) forControlEvents:UIControlEventTouchUpInside];
    
    self.recognitionButton = [[UIButton alloc] init];
    [self.view addSubview:self.recognitionButton];
    [self.recognitionButton setBackgroundColor:[UIColor blackColor]];
    [self.recognitionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.recognitionButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.speechButton.mas_bottom).offset(20);
        make.left.right.equalTo(self.textView);
        make.height.equalTo(@45);
    }];
    [self.recognitionButton setTitle:@"Recognition" forState:UIControlStateNormal];
    [self.recognitionButton addTarget:self action:@selector(startRecognizing:) forControlEvents:UIControlEventTouchUpInside];
    
    
}
- (void)initEngine {
    if (!self.speechRecognizer) {
        // 设置语言
        NSLocale *locale = [NSLocale localeWithLocaleIdentifier:@"zh-CN"];
        if (@available(iOS 10.0, *)) {
            self.speechRecognizer = [[SFSpeechRecognizer alloc] initWithLocale:locale];
        } else {
            // Fallback on earlier versions
        }
    }
    if (!self.audioEngine) {
        self.audioEngine = [[AVAudioEngine alloc] init];
    }
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    if (@available(iOS 10.0, *)) {
        [audioSession setCategory:AVAudioSessionCategoryRecord mode:AVAudioSessionModeMeasurement options:AVAudioSessionCategoryOptionDuckOthers error:nil];
    } else {
        // Fallback on earlier versions
    }
    [audioSession setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
    
    if (self.recognitionRequest) {
        [self.recognitionRequest endAudio];
        self.recognitionRequest = nil;
    }
    if (@available(iOS 10.0, *)) {
        self.recognitionRequest = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
    } else {
        // Fallback on earlier versions
    }
    self.recognitionRequest.shouldReportPartialResults = YES;
}


- (void)startRecording:(UIButton *)recordButton {
    
    recordButton.selected = !recordButton.selected;
    if (@available(iOS 10.0, *)) {
        
        if (recordButton.selected) {
            [self initEngine];
            
            AVAudioFormat *recordingFormat = [[self.audioEngine inputNode] outputFormatForBus:0];
            [[self.audioEngine inputNode] installTapOnBus:0 bufferSize:1024 format:recordingFormat block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
                [self.recognitionRequest appendAudioPCMBuffer:buffer];
            }];
            [self.audioEngine prepare];
            [self.audioEngine startAndReturnError:nil];
            
            [recordButton setTitle:@"录音ing" forState:UIControlStateNormal];
            
            
            [self.speechRecognizer recognitionTaskWithRequest:self.recognitionRequest resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
                NSLog(@"\nis final: %d  result: %@", result.isFinal, result.bestTranscription.formattedString);
                if (result.isFinal) {
                    self.textView.text = [NSString stringWithFormat:@"%@%@", self.textView.text, result.bestTranscription.formattedString];
                }
            }];
        }else{
            [self.recognitionRequest endAudio];
            self.recognitionRequest = nil;
            
            [[self.audioEngine inputNode] removeTapOnBus:0];
            [self.audioEngine stop];
            [recordButton setTitle:@"录音" forState:UIControlStateNormal];
        }
    }else{
        
    }
    
}

- (void)startRecognizing:(UIButton *)sender {
    if (@available(iOS 10.0, *)) {
        sender.selected = !sender.selected;
        
        if (sender.selected) {
            [sender setTitle:@"识别中..." forState:UIControlStateNormal];
            
            SFSpeechRecognizer *recognizer = [[SFSpeechRecognizer alloc] initWithLocale:[NSLocale localeWithLocaleIdentifier:@"zh_CN"]];
            NSURL *url = [[NSBundle mainBundle] URLForResource:@"任然-你好陌生人.mp3" withExtension:nil];
            SFSpeechURLRecognitionRequest *request = [[SFSpeechURLRecognitionRequest alloc] initWithURL:url];
            [recognizer recognitionTaskWithRequest:request resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
                if (result.isFinal) {
                    
                    self.textView.text = [NSString stringWithFormat:@"%@%@", self.textView.text, result.bestTranscription.formattedString];
                    
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"识别结果" message:[NSString stringWithFormat:@"%@", result.bestTranscription.formattedString] preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *confirm = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
                    [alert addAction:confirm];
                    [self presentViewController:alert animated:YES completion:nil];
                }
            }];
        }else{
            [sender setTitle:@"识别" forState:UIControlStateNormal];
        }
    }
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
}





-(void)handleSpeechString:(NSString *)content
{
    if ([content hasPrefix:@"打开"] || [content hasPrefix:@"open"]) {
        
    }else if ([content hasPrefix:@"搜索"] || [content hasPrefix:@"查询"]){
        
    }else if ([content hasPrefix:@"搜索"] || [content hasPrefix:@"查询"]){
        
    }
}





- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}


@end
