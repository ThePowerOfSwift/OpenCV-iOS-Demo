//
//  ZZPhotoPickerViewController.m
//  ZZFramework
//
//  Created by Yuan on 15/7/7.
//  Copyright (c) 2015年 zzl. All rights reserved.
//



#import "ZZPhotoPickerViewController.h"
#import "ZZPhotoDatas.h"
#import "ZZPhotoPickerCell.h"
#import "ZZPhotoHud.h"
#import "ZZPhotoAlert.h"
#import "ZZAlumAnimation.h"
#import "ZZPhoto.h"
#import "ZZPhotoPickerFooterView.h"
#import "BingLiYun-Swift.h"

@interface ZZPhotoPickerViewController ()<UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout>

@property (strong, nonatomic) NSMutableArray              *photoArray;
@property (strong, nonatomic) NSMutableArray              *selectArray;

@property (strong, nonatomic) UICollectionView            *picsCollection;

@property (strong, nonatomic) UIBarButtonItem             *backBtn;
@property (strong, nonatomic) UIBarButtonItem             *cancelBtn;

//@property (strong, nonatomic) UIButton                    *doneBtn;                       //完成按钮
//@property (strong, nonatomic) UIButton                    *previewBtn;                    //预览按钮

//@property (strong, nonatomic) UILabel                     *totalRound;                     //小红点
//@property (strong, nonatomic) UILabel                     *numSelectLabel;

@property (strong, nonatomic) ZZPhotoDatas                *datas;

@end

@implementation ZZPhotoPickerViewController

-(instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
    }
    return self;
}

#pragma SETUP backButtonUI Method
- (UIBarButtonItem *)backBtn{
    if (!_backBtn) {

        UIButton *back_btn = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 45, 44)];
        [back_btn setTitle:[ObjectiveCLocalizable SwiftDLocalizedString:@"取消"] forState:UIControlStateNormal];
        back_btn.titleLabel.font = [UIFont systemFontOfSize:12.0f];
        [back_btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        back_btn.frame = CGRectMake(0, 0, 45, 44);
        [back_btn addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];

        _backBtn = [[UIBarButtonItem alloc] initWithCustomView:back_btn];
        
    }
    return _backBtn;
}

#pragma SETUP cancelButtonUI Method
- (UIBarButtonItem *)cancelBtn{
    if (!_cancelBtn) {
        UIButton *button = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 60, 44)];
        [button addTarget:self action:@selector(done) forControlEvents:UIControlEventTouchUpInside];
        button.titleLabel.font = [UIFont systemFontOfSize:12.0f];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button setTitle:[ObjectiveCLocalizable SwiftDLocalizedString:@"完成"] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor colorWithRed:251/255.0 green:103/255.0 blue:104/255.0 alpha:1] forState:UIControlStateNormal];
        
        _cancelBtn = [[UIBarButtonItem alloc] initWithCustomView:button];
        
    }
    return _cancelBtn;
}

#pragma mark SETUP doneButtonUI Method

//- (UIButton *)doneBtn{
//    if (!_doneBtn) {
//        _doneBtn = [[UIButton alloc]initWithFrame:CGRectMake(ZZ_VW - 60, 0, 50, 44)];
//        [_doneBtn addTarget:self action:@selector(done) forControlEvents:UIControlEventTouchUpInside];
//        _doneBtn.titleLabel.font = [UIFont systemFontOfSize:17.0f];
//        [_doneBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
//        [_doneBtn setTitle:@"完成" forState:UIControlStateNormal];
//        [_doneBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
//    }
//    return _doneBtn;
//}

#pragma merk SETUP previewButtonUI Method

//- (UIButton *)previewBtn{
//    if (!_previewBtn) {
//        _previewBtn = [[UIButton alloc]initWithFrame:CGRectMake(10, 0, 50, 44)];
//        [_previewBtn addTarget:self action:@selector(preview) forControlEvents:UIControlEventTouchUpInside];
//        _previewBtn.titleLabel.font = [UIFont systemFontOfSize:17.0f];
//        [_previewBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
//        [_previewBtn setTitle:@"预览" forState:UIControlStateNormal];
//        [_previewBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
//    }
//    return _previewBtn;
//}

- (void)back{
    [self dismissViewControllerAnimated:YES completion:nil];
}

//- (void)cancel{
//    [self dismissViewControllerAnimated:YES completion:nil];
//}

#pragma mark --- 完成然后回调
- (void)done{

    if ([self.selectArray count] == 0) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }else{
        [ZZPhotoHud showActiveHud];
        __block NSMutableArray<ZZPhoto *> *photos = [NSMutableArray array];
        __weak __typeof(self) weakSelf = self;
        for (int i = 0; i < self.selectArray.count; i++) {
            ZZPhoto *photo = [self.selectArray objectAtIndex:i];
            [self.datas GetImageObject:photo.asset complection:^(UIImage *image,NSURL *imageUrl) {
                
                if (image){
                    ZZPhoto *model = [[ZZPhoto alloc]init];
                    model.asset = photo.asset;
                    model.originImage = image;
                    model.imageUrl = imageUrl;
                    model.createDate = photo.asset.creationDate;
                    [photos addObject:model];
                }
                if (photos.count < weakSelf.selectArray.count){
                    return;
                }
                if (weakSelf.PhotoResult) {
                    weakSelf.PhotoResult(photos);
                }
                
                [ZZPhotoHud hideActiveHud];
                [weakSelf dismissViewControllerAnimated:YES completion:nil];
            }];
        }
 
    }
}

////预览按钮，弹出图片浏览器
//- (void)preview{
//    
//    if (self.selectArray.count == 0) {
//        [self showPhotoPickerAlertView:[ObjectiveCLocalizable SwiftDLocalizedString:@"提示"] message:@"您还没有选中图片，不需要预览"];
//    }else{
//        NSLog(@"preview======");
//    }
//
//}

#pragma Declaration Array
- (NSMutableArray *)photoArray
{
    if (!_photoArray) {
        _photoArray = [NSMutableArray array];
    }
    return _photoArray;
}

- (NSMutableArray *)selectArray
{
    if (!_selectArray) {
        _selectArray = [NSMutableArray array];
    }
    return _selectArray;
}

#pragma mark ---  懒加载图片数据
- (ZZPhotoDatas *)datas{
    if (!_datas) {
        _datas = [[ZZPhotoDatas alloc]init];

    }
    return _datas;
}

#pragma mark ---  红色小圆点
//- (UILabel *)totalRound{
//    if (!_totalRound) {
//        _totalRound = [[UILabel alloc]initWithFrame:CGRectMake(ZZ_VW - 90, 10, 22, 22)];
//        if (self.roundColor == nil) {
//            _totalRound.backgroundColor = [UIColor redColor];
//        }else{
//            _totalRound.backgroundColor = self.roundColor;
//        }
//        _totalRound.layer.masksToBounds = YES;
//        _totalRound.textAlignment = NSTextAlignmentCenter;
//        _totalRound.textColor = [UIColor whiteColor];
//        _totalRound.text = @"0";
//        [_totalRound.layer setCornerRadius:CGRectGetHeight([_totalRound bounds]) / 2];
//    }
//    return _totalRound;
//}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initInterUI];
    
    [self loadPhotoData];
    // 更新UI
    [self makeCollectionViewUI];
//    //创建底部工具栏
//    [self makeTabbarUI];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.navigationController.navigationBar setBarTintColor:[UIColor whiteColor]];
    [self.navigationController.navigationBar setTranslucent:NO];
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor blackColor]}];

}

- (void)initInterUI
{
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.view.backgroundColor                 = [UIColor whiteColor];
    self.navigationItem.leftBarButtonItem     = self.backBtn;
    self.navigationItem.rightBarButtonItem    = self.cancelBtn;
}

//- (void)makeTabbarUI
//{
//    UIView *view = [[UIView alloc]initWithFrame:CGRectZero];
//    view.backgroundColor = ZZ_RGB(245, 245, 245);
//    view.translatesAutoresizingMaskIntoConstraints = NO;
//    [view addSubview:self.doneBtn];
//    [view addSubview:self.previewBtn];
//    [view addSubview:self.totalRound];
//    [self.view addSubview:view];
//    NSLayoutConstraint *tab_left = [NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeLeft multiplier:1 constant:0.0f];
//    
//    NSLayoutConstraint *tab_right = [NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeRight multiplier:1 constant:0.0f];
//    
//    NSLayoutConstraint *tab_bottom = [NSLayoutConstraint constraintWithItem:_picsCollection attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeTop multiplier:1 constant:0.0f];
//    
//    NSLayoutConstraint *tab_height = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:44];
//    
//    [self.view addConstraints:@[tab_left,tab_right,tab_bottom,tab_height]];
//    
//    
//    UIView *viewLine = [[UIView alloc]initWithFrame:CGRectMake(0, 0, ZZ_VW, 1)];
//    viewLine.backgroundColor = ZZ_RGB(230, 230, 230);
//    viewLine.translatesAutoresizingMaskIntoConstraints = NO;
//    [view addSubview:viewLine];
//}

- (void)makeCollectionViewUI
{
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc]init];
    
    CGFloat photoSize = ([UIScreen mainScreen].bounds.size.width - 3) / 4;
    flowLayout.minimumInteritemSpacing = 1.0;//item 之间的行的距离
    flowLayout.minimumLineSpacing = 1.0;//item 之间竖的距离
    flowLayout.itemSize = (CGSize){photoSize,photoSize};
    flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    
    _picsCollection = [[UICollectionView alloc]initWithFrame:CGRectZero collectionViewLayout:flowLayout];
    [_picsCollection registerClass:[ZZPhotoPickerCell class] forCellWithReuseIdentifier:@"PhotoPickerCell"];
    [_picsCollection registerClass:[ZZPhotoPickerFooterView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"FooterView"];
    flowLayout.footerReferenceSize = CGSizeMake(ZZ_VW, 70);
    _picsCollection.delegate = self;
    _picsCollection.dataSource = self;
    _picsCollection.backgroundColor = [UIColor whiteColor];
    [_picsCollection setUserInteractionEnabled:YES];
    _picsCollection.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_picsCollection];
    [_picsCollection reloadData];
    
    
    NSLayoutConstraint *pic_top = [NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_picsCollection attribute:NSLayoutAttributeTop multiplier:1 constant:0.0f];
    
    NSLayoutConstraint *pic_bottom = [NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_picsCollection attribute:NSLayoutAttributeBottom multiplier:1 constant:0.0f];
    
    NSLayoutConstraint *pic_left = [NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_picsCollection attribute:NSLayoutAttributeLeft multiplier:1 constant:0.0f];
    
    NSLayoutConstraint *pic_right = [NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_picsCollection attribute:NSLayoutAttributeRight multiplier:1 constant:0.0f];
    
    [self.view addConstraints:@[pic_top,pic_bottom,pic_left,pic_right]];
    
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
//    //滚动到底部
//    if (self.photoArray.count != 0) {
//        [_picsCollection scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:self.photoArray.count - 1 inSection:0] atScrollPosition:UICollectionViewScrollPositionBottom animated:NO];
//    }
}

- (void)loadPhotoData
{
    if (_isAlubSeclect == YES) {
        self.photoArray = [self.datas GetPhotoAssets:_fetch];

    }else{
        self.navigationItem.title = [ObjectiveCLocalizable SwiftDLocalizedString:@"选择图片"];
        self.photoArray = [self.datas GetPhotoAssets:[self.datas GetCameraRollFetchResul]];
    }
}


#pragma mark 关键位置，选中的在数组中添加，取消的从数组中减少
- (void)selectPhotoAtIndex:(NSInteger)index
{
    ZZPhoto *photo = [self.photoArray objectAtIndex:index];
    
    if (photo != nil) {
        if (photo.isSelect == NO) {
            
            if (self.selectArray.count + 1 > _selectNum) {
                
                [self showSelectPhotoAlertView:_selectNum];
                
            }else{
                //[[ZZAlumAnimation sharedAnimation] roundAnimation:self.totalRound];
                
                if ([self.datas CheckIsiCloudAsset:photo.asset] == YES) {
                    [[ZZPhotoAlert sharedAlert] showPhotoAlert];
                }else{
                    photo.isSelect = YES;
                    [self changeSelectButtonStateAtIndex:index withPhoto:photo];
                    [self.selectArray insertObject:[self.photoArray objectAtIndex:index] atIndex:self.selectArray.count];
                    self.navigationItem.title = [NSString stringWithFormat:@"%lu%@",(unsigned long)self.selectArray.count,[ObjectiveCLocalizable SwiftDLocalizedString:@"张图片"]];
                }
            }
            
        }else{
            
            photo.isSelect = NO;
            [self changeSelectButtonStateAtIndex:index withPhoto:photo];
            [self.selectArray removeObject:[self.photoArray objectAtIndex:index]];
//            [[ZZAlumAnimation sharedAnimation] roundAnimation:self.totalRound];
//            self.totalRound.text = [NSString stringWithFormat:@"%lu",(unsigned long)self.selectArray.count];
            self.navigationItem.title = [NSString stringWithFormat:@"%lu%@",(unsigned long)self.selectArray.count,[ObjectiveCLocalizable SwiftDLocalizedString:@"张图片"]];
            
        }
    }
    
}

- (void)changeSelectButtonStateAtIndex:(NSInteger)index withPhoto:(ZZPhoto *)photo
{
    ZZPhotoPickerCell *cell = (ZZPhotoPickerCell *)[_picsCollection cellForItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
    cell.isSelect = photo.isSelect;
}

#pragma UICollectionView --- Datasource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.photoArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{

    ZZPhotoPickerCell *photoCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PhotoPickerCell" forIndexPath:indexPath];
    
    __unsafe_unretained __typeof(self) weakSelf = self;
    
    photoCell.selectBlock = ^(){
        
        [weakSelf selectPhotoAtIndex:indexPath.row];
        
    };
    
    [photoCell loadPhotoData:[self.photoArray objectAtIndex:indexPath.row]];
    
    return photoCell;
}
#pragma UICollectionView --- Delegate
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath

{
    ZZPhotoPickerFooterView *footerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"FooterView" forIndexPath:indexPath];
    
    footerView.total_photo_num = _photoArray.count;
    
    return footerView;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"didSelectItemAtIndexPath====");
    [self selectPhotoAtIndex:indexPath.row];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section
{
    return CGSizeMake(self.view.frame.size.width, 60);
}

- (void)showSelectPhotoAlertView:(NSInteger)photoNumOfMax
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[ObjectiveCLocalizable SwiftDLocalizedString:@"提示"] message:[NSString stringWithFormat:@"%@%lu%@",[ObjectiveCLocalizable SwiftDLocalizedString:@"最多只能选择"],(long)photoNumOfMax,[ObjectiveCLocalizable SwiftDLocalizedString:@"张图片"]]preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *action1 = [UIAlertAction actionWithTitle:[ObjectiveCLocalizable SwiftDLocalizedString:@"确定"] style:UIAlertActionStyleCancel handler:^(UIAlertAction *action){
        
    }];
    
    [alert addAction:action1];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showPhotoPickerAlertView:(NSString *)title message:(NSString *)message
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *action1 = [UIAlertAction actionWithTitle:[ObjectiveCLocalizable SwiftDLocalizedString:@"确定"] style:UIAlertActionStyleCancel handler:^(UIAlertAction *action){
        
    }];
    
    [alert addAction:action1];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
