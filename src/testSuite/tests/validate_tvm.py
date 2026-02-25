#!/usr/bin/env python3
"""
TVM Unit Test Validator
Loads test cases from tvm.txt and validates equation accuracy.
"""


# TVM EQUATION VALIDATOR
# ======================
#
# Usgae: python3 validate_tvm.py tvm.txt
# 
# PURPOSE:
# This script validates that TVM (Time Value of Money) solutions satisfy the
# fundamental equation to the required precision. It does NOT solve for variables;
# it only verifies that given solutions are mathematically correct.
#
# INPUT PARAMETERS (from test cases):
#   N        - Number of payment periods (V2036)
#   I%/a     - Annual interest rate percentage (V2035)
#   PV       - Present value (V2039)
#   PMT      - Payment amount (V2038)
#   FV       - Future value (V2034)
#   pp/a     - Payment periods per year (V2037)
#   cp/a     - Compounding periods per year (V2043)
#   FL_ENDPMT - Payment timing: 0=BEGIN, 1=END
#
# TVM FUNDAMENTAL EQUATION:
# The validator checks that all test cases satisfy:
#   PV + PMT × annuity_factor × (1 + ip×p) + FV × (1 + ip)^(-N) ≈ 0
# 
# Where:
#   ip = effective interest rate per payment period, calculated from:
#        - If pp/a = cp/a: ip = (I%/a / 100) / pp/a
#        - If pp/a ≠ cp/a: ip = (1 + I%/a/(100×cp/a))^(cp/a/pp/a) - 1
#   p = payment timing (0 for END mode, 1 for BEGIN mode)
#   annuity_factor = [1 - (1+ip)^(-N)] / ip  (or N if ip ≈ 0)
#
# VALIDATION METHOD:
# For each test case:
# 1. Extract N, I%/a, PV, PMT, FV, pp/a, cp/a, and payment mode from test data
# 2. Calculate effective interest rate ip from I%/a, pp/a, and cp/a
# 3. Calculate all three components (PV, PMT, FV) of the equation
# 4. Sum them to get the equation error
# 5. Compare error to the maximum component magnitude (relative error)
# 6. Pass/fail based on relative error threshold (1e-32)
#
# RELATIVE ERROR:
# Relative error = |equation_error| / max(|PV_component|, |PMT_component|, |FV_component|)
# 
# For 34-digit output precision with 51-digit internal arithmetic:
# - Expected relative error: < 1e-32 (allows ~2 guard digits of error)
# - Relative error of 1e-35 means 35+ correct digits
# - Relative error floored at 1e-34 for exact results (one ULP of 34-digit input precision)
# - Any error > 1e-32 indicates a precision problem in the calculation
#
# TEST FILE FORMAT:
# Reads tvm.txt containing test cases in the format:
#   Func: fnTvmVar(XXXX)     - which variable was solved
#   In: V2036=Real:"..."     - input values for N, I%, PV, PMT, FV, pp/a, cp/a
#   In: FL_ENDPMT=0          - payment timing (0=BEGIN, 1=END)
#   Out: V2038=Real:"..."    - output solution value
#
# WHAT IT DOES NOT DO:
# - Does not solve for any variables
# - Does not test iteration algorithms (Newton-Raphson, etc.)
# - Does not verify calculation speed or convergence
# - Only validates that the final answers satisfy the equation
#
# EXPECTED RESULTS:
# - Direct calculations (PMT, PV, FV): Should pass with ~35 digits accuracy
# - Iterative solvers (I%, N): May show reduced accuracy depending on 
#   iteration convergence and termination criteria




from decimal import Decimal, getcontext
import re
import sys

# Set high precision for validation
getcontext().prec = 60

# Variable mappings
VAR_MAP = {
    '2034': 'FV',
    '2035': 'I%/a',
    '2036': 'N',
    '2037': 'pp/a',
    '2038': 'PMT',
    '2039': 'PV',
    '2043': 'cp/a'
}

def calculate_effective_rate(i_percent_per_year, compound_per_year, payment_per_year):
    """Calculate effective interest rate per payment period."""
    if i_percent_per_year == 0:
        return Decimal(0)
    
    i_annual = Decimal(i_percent_per_year) / Decimal(100)
    c_per_y = Decimal(compound_per_year)
    p_per_y = Decimal(payment_per_year)
    
    if c_per_y == p_per_y:
        ip = i_annual / p_per_y
    else:
        ic = i_annual / c_per_y
        exponent = c_per_y / p_per_y
        ip = (1 + ic) ** exponent - 1
    
    return ip

def validate_tvm(pv, fv, pmt, nper, i_percent, payment_per_year, compound_per_year, begin_mode):
    """
    Validate TVM equation: PV + PMT*annuity*(1+ip*p) + FV*(1+ip)^(-N) = 0
    Returns (error, max_component, relative_error)
    """
    pv = Decimal(str(pv))
    fv = Decimal(str(fv))
    pmt = Decimal(str(pmt))
    nper = Decimal(str(nper))
    
    # Calculate effective rate
    ip = calculate_effective_rate(i_percent, compound_per_year, payment_per_year)
    
    # Payment timing factor
    p = Decimal(1) if begin_mode else Decimal(0)
    
    # Calculate power term and annuity
    if abs(ip) < 1e-37:
        power_term = Decimal(1)
        annuity_factor = nper
    else:
        power_term = (1 + ip) ** (-nper)
        annuity_factor = (1 - power_term) / ip
    
    # TVM equation components
    pv_component = pv
    pmt_component = pmt * annuity_factor * (1 + ip * p)
    fv_component = fv * power_term
    
    # Total should equal zero
    total = pv_component + pmt_component + fv_component
    
    # Find largest component for relative error
    max_component = max(abs(pv_component), abs(pmt_component), abs(fv_component))
    
    if max_component == 0:
        relative_error = abs(total)
    else:
        relative_error = abs(total / max_component)
    
    # A relative error of exactly zero is meaningless for 34-digit inputs.
    # Floor at 1e-34 (one ULP) to reflect the actual input precision limit.
    if relative_error == 0:
        relative_error = Decimal('1e-34')

    return total, max_component, relative_error

def extract_endpmt_flag(line):
    """Extract FL_ENDPMT value from a line. Returns 0 (BEGIN), 1 (END), or None."""
    if 'FL_ENDPMT=0' in line:
        return 0  # BEGIN
    elif 'FL_ENDPMT=1' in line:
        return 1  # END
    return None

def parse_test_case(lines, start_idx, global_begin_mode):
    """
    Parse a single test case starting at start_idx.
    Returns (test_dict, next_line_idx) or (None, next_line_idx) if no test found.
    """
    i = start_idx
    while i < len(lines):
        line = lines[i].strip()
        
        # Skip blank lines and pure comments
        if not line or (line.startswith(';') and 'Func:' not in line):
            i += 1
            continue
        
        # Check for Func: line (start of test)
        if line.startswith('Func: fnTvmVar('):
            # Extract test name from previous comment lines
            test_name = "Test"
            for j in range(max(0, i-3), i):
                if lines[j].strip().startswith(';') and not lines[j].strip().startswith(';;'):
                    test_name = lines[j].strip()[1:].strip()
                    break
            
            # Extract which variable is being solved
            match = re.search(r'fnTvmVar\((\d+)\)', line)
            if not match:
                i += 1
                continue
            solved_var = match.group(1)
            
            # Check if there's an In: FL_ENDPMT line right before this Func: line
            # (within 2 lines back)
            test_specific_mode = None
            for j in range(max(0, i-2), i):
                prev_line = lines[j].strip()
                if prev_line.startswith('In:') and 'FL_ENDPMT' in prev_line and 'V2' not in prev_line:
                    flag = extract_endpmt_flag(prev_line)
                    if flag is not None:
                        test_specific_mode = (flag == 0)  # 0 = BEGIN (True), 1 = END (False)
                        break
            
            # Find In: line(s) and Out: line
            test_data = {
                'name': test_name,
                'solved_var': VAR_MAP.get(solved_var, solved_var),
                'begin_mode': test_specific_mode if test_specific_mode is not None else global_begin_mode,
                'values': {}
            }
            
            i += 1
            first_in_line = True
            while i < len(lines):
                line = lines[i].strip()
                
                # Check for FL_ENDPMT in first In: line after Func:
                if first_in_line and line.startswith('In:') and 'FL_ENDPMT' in line:
                    flag = extract_endpmt_flag(line)
                    if flag is not None:
                        test_data['begin_mode'] = (flag == 0)
                    first_in_line = False
                
                # Parse In: lines
                if line.startswith('In:'):
                    first_in_line = False
                    # Extract all V#### values
                    for var_code in ['2034', '2035', '2036', '2037', '2038', '2039', '2043']:
                        pattern = f'V{var_code}=Real:"([^"]+)"'
                        match = re.search(pattern, line)
                        if match:
                            test_data['values'][var_code] = match.group(1)
                
                # Parse Out: line
                if line.startswith('Out:'):
                    pattern = f'V{solved_var}=Real:"([^"]+)"'
                    match = re.search(pattern, line)
                    if match:
                        test_data['values'][solved_var] = match.group(1)
                    i += 1
                    break
                
                i += 1
            
            # Check if we have all required values
            if all(k in test_data['values'] for k in ['2034', '2035', '2036', '2037', '2038', '2039', '2043']):
                return test_data, i
        
        # If we reach here, this line is not a test start - return immediately
        # so load_test_file can process it (e.g., mode-setting lines)
        return None, start_idx + 1
    
    return None, len(lines)

def load_test_file(filename):
    """Load and parse all test cases from file."""
    try:
        with open(filename, 'r') as f:
            lines = f.readlines()
    except FileNotFoundError:
        print(f"Error: File '{filename}' not found")
        sys.exit(1)
    
    tests = []
    i = 0
    begin_mode = False  # Track global BEGIN/END state (False = END, True = BEGIN)
    
    while i < len(lines):
        line = lines[i].strip()
        
        # Track FL_ENDPMT state globally from standalone In: lines
        # (lines that have FL_ENDPMT but no V2xxx variables or other data)
        if line.startswith('In:') and 'FL_ENDPMT' in line:
            # Check if this is a standalone mode-setting line (no variables, no AM=, no RX=)
            if 'V2' not in line and 'RX=' not in line and 'AM=' not in line:
                # This is a global mode setter
                flag = extract_endpmt_flag(line)
                if flag is not None:
                    begin_mode = (flag == 0)  # 0 = BEGIN, 1 = END
        
        test, new_i = parse_test_case(lines, i, begin_mode)
        if test:
            tests.append(test)
            i = new_i
        else:
            i += 1
    
    return tests

def main():
    filename = 'tvm.txt'
    if len(sys.argv) > 1:
        filename = sys.argv[1]
    
    print("=" * 110)
    print(f"TVM VALIDATION TEST - Loading from {filename}")
    print("=" * 110)
    print()
    
    tests = load_test_file(filename)
    
    if not tests:
        print("No tests found in file!")
        return
    
    print(f"Found {len(tests)} test cases")
    print()
    print(f"{'Test Name':<45} {'Mode':>6} {'Error':>15} {'Max Comp':>12} {'Rel Error':>12}")
    print("-" * 110)
    
    passed = 0
    failed = 0
    max_rel_error = Decimal(0)
    
    for test in tests:
        vals = test['values']
        
        try:
            error, max_comp, rel_error = validate_tvm(
                vals['2039'],  # PV
                vals['2034'],  # FV
                vals['2038'],  # PMT
                vals['2036'],  # N
                vals['2035'],  # I%/a
                vals['2037'],  # pp/a
                vals['2043'],  # cp/a
                test['begin_mode']
            )
            
            # Success threshold: relative error < 1e-32 (allows ~2 guard digits of error in 34-digit output)
            is_pass = rel_error < Decimal('1e-32')
            
            status = "✓" if is_pass else "✗"
            passed += 1 if is_pass else 0
            failed += 0 if is_pass else 1
            
            mode_str = "BEGIN" if test['begin_mode'] else "END"
            error_str = f"{float(error):.2e}"
            max_comp_str = f"{float(max_comp):.2e}"
            rel_error_str = f"{float(rel_error):.2e}"
            
            # Truncate long test names
            name = test['name'][:43]
            
            print(f"{status} {name:<43} {mode_str:>6} {error_str:>15} {max_comp_str:>12} {rel_error_str:>12}")
            
            max_rel_error = max(max_rel_error, rel_error)
            
        except Exception as e:
            print(f"✗ {test['name']:<43} ERROR: {str(e)}")
            failed += 1
    
    print("-" * 110)
    print()
    print(f"Results: {passed} passed, {failed} failed")
    print(f"Maximum relative error: {float(max_rel_error):.2e}")
    print()
    
    if max_rel_error < Decimal('1e-32'):
        print("✓ Excellent: All results accurate to 32+ digits")
    elif max_rel_error < Decimal('1e-28'):
        print("✓ Good: All results accurate to 28+ digits")
    else:
        print(f"⚠ Warning: Some results show reduced precision")
    
    print("=" * 110)

if __name__ == "__main__":
    main()
