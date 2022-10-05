from pathlib import Path

def validate_path_as_uri(path):
    #ensures that path formatting is amenable to urlopen-ing, i.e. converts to absolute URI

    p = Path(path)

    if p.parts[0] == "https:":
        return path
    else:
        if p.is_absolute():
            return p.as_uri()
        else:
            p = p.resolve()
            return p.as_uri()
