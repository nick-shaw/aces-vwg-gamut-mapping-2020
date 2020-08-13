#!/usr/bin/env python
# -*- coding: utf-8 -*-

from __future__ import division

import numpy as np
import warnings
warnings.filterwarnings("ignore")

from gamut_compress import gamut_compression_operator, compress

rgb = np.array([[-0.1, 0.2, 0.3],
                [-0.1, -0.2, 0.3],
                [-0.1, -0.2, -0.3]])

print("Original:\n{}".format(rgb))

print("\nNormal (fwd):")
print(gamut_compression_operator(rgb))
print("\nNormal (rev):")
print(gamut_compression_operator(gamut_compression_operator(rgb), invert=True))

print("\nHexagonal (fwd):")

print(gamut_compression_operator(rgb, hexagonal=True))
print("\nHexagonal (rev):")
print(gamut_compression_operator(gamut_compression_operator(rgb, hexagonal=True), hexagonal=True, invert=True))
