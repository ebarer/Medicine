//
//  MainTVC+UIViewControllerPreviewing.swift
//  Medicine
//
//  Created by Elliot Barer on 2015-10-01.
//  Copyright © 2015 Elliot Barer. All rights reserved.
//

import UIKit

extension MedicineDetailsTVC: UIViewControllerPreviewingDelegate {
    
    // Create a previewing view controller to be shown at "Peek".
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        // Obtain the index path and the cell that was pressed.
        guard let indexPath = tableView.indexPathForRow(at: location),
            let cell = tableView.cellForRow(at: indexPath) else { return nil }
        
        // Set the source rect to the cell frame, so surrounding elements are blurred.
        previewingContext.sourceRect = cell.frame
        
        // Create a detail view controller and set its properties.
        if indexPath.section == 2 {
            switch indexPath.row {
            case 0: // Dose History
                guard let vc = storyboard?.instantiateViewController(withIdentifier: "doseHistory") as? MedicineDoseHistoryTVC else { return nil }
                vc.med = med
                return vc
            case 1: // Refill History
                guard let vc = storyboard?.instantiateViewController(withIdentifier: "refillHistory") as? MedicineRefillHistoryTVC else { return nil }
                vc.med = med
                return vc
            default:
                return nil
            }
        }
        
        return nil
    }
    
    // Present the view controller for the "Pop" action.
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        show(viewControllerToCommit, sender: self)
    }
}
