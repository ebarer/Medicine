//
//  MainTVC+UIViewControllerPreviewing.swift
//  Medicine
//
//  Created by Elliot Barer on 2015-10-01.
//  Copyright © 2015 Elliot Barer. All rights reserved.
//

import UIKit

extension MainVC: UIViewControllerPreviewingDelegate {
    
    // Create a previewing view controller to be shown at "Peek".
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        // Obtain the index path and the cell that was pressed.
        guard let indexPath = tableView.indexPathForRow(at: location),
            let cell = tableView.cellForRow(at: indexPath) else {
            return nil
        }
        
        // Create a detail view controller and set its properties.
        guard let vc = UIStoryboard(name: "MedicineDetails", bundle: Bundle.main).instantiateViewController(withIdentifier: "MedicineDetailsTVC") as? MedicineDetailsTVC else {
            return nil
        }
        
        guard let med = fetchedResultsController?.object(at: indexPath) as? Medicine else {
            return nil
        }
        
        vc.med = med
        
        // Set the source rect to the cell frame, so surrounding elements are blurred.
        previewingContext.sourceRect = cell.frame
        
        return vc
    }
    
    // Present the view controller for the "Pop" action.
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        show(viewControllerToCommit, sender: self)
    }
}
