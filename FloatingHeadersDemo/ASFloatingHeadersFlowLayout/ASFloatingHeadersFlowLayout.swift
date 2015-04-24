//
//  ASFloatingHeadersFlowLayout.swift
//  FloatingHeadersDemo
//
//  Created by Andrey Syvrachev on 22.04.15.
//  Copyright (c) 2015 Andrey Syvrachev. All rights reserved.
//

import UIKit

class ASFloatingHeadersFlowLayout: UICollectionViewFlowLayout {
    
    var sectionAttributes:[(header:UICollectionViewLayoutAttributes!,footer:UICollectionViewLayoutAttributes!)] = []
    let offsets = NSMutableOrderedSet()
    var floatingSectionIndex:Int! = nil
    var previousWidth:CGFloat! = nil
    
    override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        return true
    }
    
    
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [AnyObject]? {

      
        let attrs = super.layoutAttributesForElementsInRect(rect)
        let ret = attrs?.map() {
            
            (attribute) -> UICollectionViewLayoutAttributes in
            
            let attr = attribute as! UICollectionViewLayoutAttributes
            
            if let elementKind = attr.representedElementKind {
                if (elementKind == UICollectionElementKindSectionHeader){
                    return self.sectionAttributes[attr.indexPath.section].header
                }
            }
            
            return attr
        }
        return ret
    }
    
    override func layoutAttributesForSupplementaryViewOfKind(elementKind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes! {
        
        setOffsetOfFloatingHeader()
        let attrs = self.sectionAttributes[indexPath.section]
        return elementKind == UICollectionElementKindSectionHeader ? attrs.header : attrs.footer

    }
   
    override func invalidationContextForBoundsChange(newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
        
        var context = super.invalidationContextForBoundsChange(newBounds)
        if let width = self.previousWidth{
            if (width != newBounds.size.width){
                self.previousWidth = newBounds.size.width
                return context
            }
        }
        
        self.previousWidth = newBounds.size.width

        let collectionView = self.collectionView!
        
        let offset:CGFloat = newBounds.origin.y + collectionView.contentInset.top
        let index = indexForOffset(offset)
      
        var invalidatedIndexPaths = [NSIndexPath(forItem: 0, inSection:index)];
        if let floatingSectionIndex = self.floatingSectionIndex {
            if (self.floatingSectionIndex != index){
                
                // have to restory previous section attributes to default
                self.sectionAttributes[floatingSectionIndex].header = super.layoutAttributesForSupplementaryViewOfKind(UICollectionElementKindSectionHeader,atIndexPath: NSIndexPath(forItem: 0, inSection: floatingSectionIndex))
                
                invalidatedIndexPaths.append(NSIndexPath(forItem: 0, inSection:floatingSectionIndex))
            }
        }
        self.floatingSectionIndex = index
        
        context.invalidateSupplementaryElementsOfKind(UICollectionElementKindSectionHeader,atIndexPaths:invalidatedIndexPaths)
        return context
    }
    
    override func prepareLayout() {
        
        let start = CFAbsoluteTimeGetCurrent()

        super.prepareLayout()

        calculateSectionAttributes()
        
        let stop = CFAbsoluteTimeGetCurrent()
        println("prepareLayout ... done in \(stop - start) sec")
    }
    
    private func calculateSectionAttributes(){
        self.sectionAttributes.removeAll(keepCapacity: true)
        self.offsets.removeAllObjects()
        
        let collectionView = self.collectionView!
        
        let numberOfSections = collectionView.numberOfSections()
        for var section = 0; section < numberOfSections; ++section {
            
            let indexPath = NSIndexPath(forItem: 0, inSection: section)
            let header =  super.layoutAttributesForSupplementaryViewOfKind(UICollectionElementKindSectionHeader,atIndexPath:indexPath)
            let footer =  super.layoutAttributesForSupplementaryViewOfKind(UICollectionElementKindSectionFooter,atIndexPath:indexPath)
            
            self.sectionAttributes.append((header:header,footer:footer))
            
            if (section > 0){
                self.offsets.addObject(header.frame.origin.y)
            }
        }
    }
    
    private func setOffsetOfFloatingHeader(){
        let collectionView = self.collectionView!
        let offset:CGFloat = collectionView.contentOffset.y + collectionView.contentInset.top
        let index = indexForOffset(offset)
        
        let footerOffset:CGFloat! = self.sectionAttributes[index].footer.frame.origin.y
        let headerHeight:CGFloat! = self.sectionAttributes[index].header.frame.size.height
        let maxOffsetForHeader = footerOffset - headerHeight
        
        self.setFloatingHeaderOffset(min(offset,maxOffsetForHeader), forIndex: index)
    }
    
    private func indexForOffset(offset: CGFloat) -> Int {
        
        let range = NSRange(location:0, length:self.offsets.count)
        return self.offsets.indexOfObject(offset,
            inSortedRange: range,
            options: .InsertionIndex,
            usingComparator: { (section0:AnyObject!, section1:AnyObject!) -> NSComparisonResult in
                let s0:CGFloat = section0 as! CGFloat
                let s1:CGFloat = section1 as! CGFloat
                return s0 < s1 ? .OrderedAscending : .OrderedDescending
        })
    }
    
    private func setFloatingHeaderOffset(offset:CGFloat, forIndex:Int){
        let attrs = self.sectionAttributes[forIndex].header
        attrs.frame = CGRectMake(0, offset, attrs.frame.size.width, attrs.frame.size.height)
        attrs.zIndex = 1024
    }
    
}
