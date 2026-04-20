import re

with open('lib/screens/sign_up_screen.dart', 'r') as f:
    content = f.read()

# Extract DOB
dob_pattern = r"(\s*// Age \(DOB\)\s*_buildLabel\('Date of Birth \(Age\)', isDark\),\s*InkWell\(\s*onTap: \(\) => _selectDate\(context\),\s*child: IgnorePointer\(\s*child: TextField\(\s*decoration: inputDecoration\(\s*_selectedDob == null\s*\?\s*'Select Date'\s*:\s*\"\$\{\_selectedDob!\.day\}/\$\{\_selectedDob!\.month\}/\$\{\_selectedDob!\.year\}\",\s*\),\s*\),\s*\),\s*\),\s*const SizedBox\(height: 16\),)"
dob_match = re.search(dob_pattern, content)
if dob_match:
    dob_text = dob_match.group(1)
    content = content.replace(dob_text, '')
else:
    print("Could not find DOB")

# Extract Height
height_pattern = r"(\s*// Height\s*_buildLabel\('Height', isDark\),\s*Row\(\s*children: \[\s*if \(_heightUnit == 'cm'\)\s*Expanded\(\s*flex: 2,\s*child: TextField\(\s*controller: _heightCmController,\s*keyboardType: TextInputType\.number,\s*decoration: inputDecoration\('cm'\),\s*\),\s*\)\s*else \.\.\.\[.*?const SizedBox\(height: 16\),)"
height_match = re.search(height_pattern, content, re.DOTALL)
if height_match:
    height_text = height_match.group(1)
    content = content.replace(height_text, '')
else:
    print("Could not find Height")

# Extract Weight
weight_pattern = r"(\s*// Weight\s*_buildLabel\('Weight', isDark\),\s*Row\(.*?const SizedBox\(height: 16\),)"
weight_match = re.search(weight_pattern, content, re.DOTALL)
if weight_match:
    weight_text = weight_match.group(1)
    content = content.replace(weight_text, '')
else:
    print("Could not find Weight")

# Insert them before the Requirement section Divider
target_insertion = r"(\s*const SizedBox\(height: 24\),\s*Divider\(\s*color: isDark\s*\?\s*const Color\(0xFF334155\)\s*:\s*const Color\(0xFFE2E8F0\)\),\s*const SizedBox\(height: 24\),\s*// Requirement Section)"
insertion_text = "\n" + (dob_text if dob_match else "") + (height_text if height_match else "") + (weight_text if weight_match else "") + r"\1"
content = re.sub(target_insertion, insertion_text, content)

# Now, ADD the new partner type and partner age dropdowns inside the requirement section
# Replace Old Language textfield with Dropdown
req_insertion = r"(\s*// Income\s*_buildLabel\('Monthly Income', isDark\),\s*Row\(.*?const SizedBox\(height: 16\),)"
# We will insert Partner Age and Partner Type before Income
partner_age = """
                                // Partner Age
                                _buildLabel('Minimum Partner Age', isDark),
                                DropdownButtonFormField<String>(
                                  value: _selectedLookingForAge,
                                  decoration: inputDecoration('Select Age Range'),
                                  items: ['18 - 25 years old', '25 - 35 years old', '35 - 45 years old', '45+ years old', 'Any age']
                                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                      .toList(),
                                  onChanged: (val) => setState(() => _selectedLookingForAge = val),
                                ),
                                const SizedBox(height: 16),
"""
partner_type = """
                                // Partner Type
                                _buildLabel('Partner Type', isDark),
                                DropdownButtonFormField<String>(
                                  value: _selectedLookingForType,
                                  decoration: inputDecoration('Select Partner Type'),
                                  items: ['Practising Muslim', 'Moderate Muslim', 'Liberal Muslim', 'Any']
                                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                      .toList(),
                                  onChanged: (val) => setState(() => _selectedLookingForType = val),
                                ),
                                const SizedBox(height: 16),
"""

if re.search(req_insertion, content, re.DOTALL):
    content = re.sub(req_insertion, partner_age + partner_type + r"\1", content, count=1, flags=re.DOTALL)
else:
    print("Could not find Income")

# Fix the Language field
lang_pattern = r"(\s*_buildLabel\('Preferred Language', isDark\),\s*)TextField\(\s*controller: _languageController,\s*decoration: inputDecoration\('e\.g\. English, Arabic, Bengali'\),\s*\),"
lang_replacement = r"""\1DropdownButtonFormField<String>(
                                  value: _selectedLanguage,
                                  decoration: inputDecoration('Select Language'),
                                  items: ['English', 'Bengali', 'Hindi', 'Urdu', 'Arabic', 'French', 'German', 'Spanish', 'Other']
                                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                      .toList(),
                                  onChanged: (val) => setState(() => _selectedLanguage = val),
                                ),"""

content = re.sub(lang_pattern, lang_replacement, content)

with open('lib/screens/sign_up_screen.dart', 'w') as f:
    f.write(content)

print("Done")
