#!/usr/bin/env python
from ansible.module_utils.basic import *
import requests
import os
from dnsimple import DNSimple

'''
parameters:
api_token       DNSimple token for account
account_id      DNSimple account id
domain          Zone from DNSimple
record          JSON object, includes type, name, content, ttl

example record:
record={
    'type':'A',
    'name':'control',
    'content':'192.168.10.1',
    'ttl':'60'
    }

state = 'present' or 'absent'
'''

def create_record(data):
    nonexistant=False
    record = {
        'type': data['type'],
        'name': data['name'],
        'content': data['content'],
        'ttl': data['ttl']
    }

    dns=DNSimple(api_token=data['dnsimple_token'],account_id=data['dnsimple_account'])
    if 'present' in data['state']:
        for n in dns.records(data['domain']):
            if record['name'] == n['record']['name']:
                res=dns.update_record(data['domain'],n['record']['id'],record)
                nonexistant=False
                return (True, res['record']['id'], 'record updated')
            else:
                nonexistant=True
        if nonexistant:
            res=dns.add_record(data['domain'], record)
            return (True, res['record']['id'], 'record added')
    return (False, "{}", 'no record added')


def delete_record(data):
    dns=DNSimple(api_token=data['dnsimple_token'],account_id=data['dnsimple_account'])
    if 'absent' in data['state']:
        for n in dns.records(data['domain']):
            if data['name'] == n['record']['name']:
                dns.delete_record(data['domain'],n['record']['id'])
                return (True, None, 'record deleted')
    return (False, None, 'no record deleted')

def main():
    fields = {
        "type": {"required": False, "default": "A", "type": "str"},
        "name": {"required": True, "type": "str"},
        "content": {"required": True, "type": "str"},
        "ttl": {"required": False, "default": "600", "type": "str"},
        "domain": {"required": True, "type": "str"},
        "dnsimple_token": {"required": True, "type": "str"},
        "dnsimple_account": {"required": True, "type": "str"},
        "state": {"default": "present","choices": ['present', 'absent'],"type": 'str'}
    }

    choice_map = {
      "present": create_record,
      "absent": delete_record
    }

    module = AnsibleModule(argument_spec=fields)
    has_changed, record_id, result = choice_map.get(module.params['state'])(module.params)
    module.exit_json(changed=has_changed, record_id=record_id, meta=result)

if __name__ == '__main__':
    main()