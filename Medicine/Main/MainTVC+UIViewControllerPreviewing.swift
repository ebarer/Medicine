//
//  MainTVC+UIViewControllerPreviewing.swift
//  Medicine
//
//  Created by Elliot Barer on 2015-10-01.
//  Copyright © 2015 Elliot Barer. All rights reserved.
//

import UIKit

@available(iOS 9.0, *)
extension MainVC: UIViewControllerPreviewingDelegate {
    
    // Create a previewing view controller to be shown at "Peek".
    func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        // Obtain the index path and the cell that was pressed.
        guard let indexPath = tableView.indexPathForRowAtPoint(location),
            cell = tableView.cellForRowAtIndexPath(indexPath) else { return nil }
        
        // Create a detail view controller and set its properties.
        guard let vc = storyboard?.instantiateViewControllerWithIdentifier("MedicineDetailsTVC") as? MedicineDetailsTVC else { return nil }
        
        vc.med = medication[indexPath.row]
        
        // Set the source rect to the cell frame, so surrounding elements are blurred.
        previewingContext.sourceRect = cell.frame
        
        return vc
    }
    
    // Present the view controller for the "Pop" action.
    func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {
        showViewController(viewControllerToCommit, sender: self)
    }
}