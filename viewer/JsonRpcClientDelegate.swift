//
// Created by Andreas Würl on 28.04.13.
// Copyright (c) 2013 Andreas Würl. All rights reserved.
//
//


import Foundation

public protocol JsonRpcClientDelegate {
    public required func receivedResponse(response :[String:AnyObject], errorInServiceCall :NSError) -> Void
}