// Copyright 2021 Dmitry Kotenko
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License.
// You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

import UIKit


public extension UIView {

    // Notify that subview's layout has been changed (probably this means that setNeedsLayout() should be called).
    func subviewLayoutInvalidated(subview: UIView) {
        superview?.subviewLayoutInvalidated(subview: self)
    }
}
