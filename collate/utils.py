"""
stringify method to write floats as numerical non-scientific notation
"""
def float_to_str(f):
    float_string = repr(f)
    if 'e' in float_string:  # detect scientific notation
        digits, exp = float_string.split('e')
        digits = digits.replace('.', '').replace('-', '')
        exp = int(exp)
        zero_padding = '0' * (abs(int(exp)) - 1)  # minus 1 for decimal point in the sci notation
        sign = '-' if f < 0 else ''
        if exp > 0:
            float_string = '{}{}{}.0'.format(sign, digits, zero_padding)
        else:
            float_string = '{}0.{}{}'.format(sign, zero_padding, digits)
    return float_string


"""
rounds to significant figures
"""
def _round_sig(x, sig=4):
    return round(x, sig - int(floor(log10(abs(x)))) - 1)


"""
prints string as decimal value not scientific notation
"""
def _format_floats(fl, sig=4):
    if type(fl) == str:
        fl = float(fl)
    if np.isnan(fl):
        return fl
    else:
        return np.format_float_positional(_round_sig(fl, sig=sig), precision=6, trim='-')


def process_pert_doses(el):
    if type(el) == str:
        #         print(el)
        return '|'.join(map(_format_floats, map(float, el.split('|'))))
    else:
        return _format_floats(el)

def process_pert_idoses(el):
    if type(el) == str:
        #         print(el)
        idoses = el.split('|')
        idoses = [i.split(" ") for i in idoses]
        return "|".join(["{} {}".format(_format_floats(idose[0]), idose[1]) for idose in idoses])
    else:
        return _format_floats(el)

def stringify_inst_doses(inst):
    # cast pert_dose field to str
    inst['pert_dose'] = inst['pert_dose'].apply(
        lambda el: process_pert_doses(el)
    )
    if 'pert_idose' in inst.columns:
        inst['pert_idose'] = inst['pert_idose'].apply(
            lambda el: process_pert_idoses(el)
        )

    inst['pert_dose'] = inst['pert_dose'].astype(str)
    return inst
