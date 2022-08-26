import os
import json

def dir_to_dict(d):
    dict = {}
    for dirpath,_,filenames in os.walk(d):
        for f in filenames:
            path = os.path.join(dirpath, f)
            dict[path] = open(path, 'r').read()
    return dict

print(json.dumps(dir_to_dict('.')))
