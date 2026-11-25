#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Dmitrii Shaburov
# SPDX-License-Identifier: GPL-3.0-or-later
"""Packs the theme folder into a .vsix (a zip with a manifest), without Node or vsce.

    python3 -I build-vsix.py SOURCE_DIR OUTPUT.vsix
"""
import json
import os
import sys
import zipfile
from xml.sax.saxutils import escape

src, out = sys.argv[1], sys.argv[2]
with open(os.path.join(src, "package.json"), encoding="utf-8") as f:
    pkg = json.load(f)

manifest = f"""<?xml version="1.0" encoding="utf-8"?>
<PackageManifest Version="2.0.0" xmlns="http://schemas.microsoft.com/developer/vsx-schema/2011" xmlns:d="http://schemas.microsoft.com/developer/vsx-schema-design/2011">
  <Metadata>
    <Identity Language="en-US" Id="{escape(pkg['name'])}" Version="{escape(pkg['version'])}" Publisher="{escape(pkg['publisher'])}" />
    <DisplayName>{escape(pkg['displayName'])}</DisplayName>
    <Description xml:space="preserve">{escape(pkg['description'])}</Description>
    <Categories>Themes</Categories>
    <Properties>
      <Property Id="Microsoft.VisualStudio.Code.Engine" Value="{escape(pkg['engines']['vscode'])}" />
    </Properties>
  </Metadata>
  <Installation>
    <InstallationTarget Id="Microsoft.VisualStudio.Code" />
  </Installation>
  <Dependencies />
  <Assets>
    <Asset Type="Microsoft.VisualStudio.Code.Manifest" Path="extension/package.json" Addressable="true" />
  </Assets>
</PackageManifest>
"""
content_types = """<?xml version="1.0" encoding="utf-8"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension=".json" ContentType="application/json" /><Default Extension=".vsixmanifest" ContentType="text/xml" /></Types>
"""

with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
    z.writestr("[Content_Types].xml", content_types)
    z.writestr("extension.vsixmanifest", manifest)
    for root, _dirs, files in os.walk(src):
        for name in sorted(files):
            path = os.path.join(root, name)
            z.write(path, "extension/" + os.path.relpath(path, src))
