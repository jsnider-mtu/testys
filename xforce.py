import requests
import json
import sys
import os
import urllib3
from collections import defaultdict
from pymisp import PyMISP, MISPAttribute, MISPEvent, MISPObject
from requests.auth import HTTPBasicAuth

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
sys.path.append('./')

class XforceExchange():
    def __init__(self, apikey, apipassword, mispapikey, mispurl):
        self.base_url = "https://api.xforce.ibmcloud.com"
        self.misp_url = mispurl
        self.misp = PyMISP(mispurl, mispapikey, ssl=False)
        self._apikey = apikey
        self._apipassword = apipassword
        self._misp_apikey = mispapikey

    def get_events(self):
        casefiles = self._api_call(f'{self.base_url}/casefiles/public')
        if 'status_code' in casefiles:
            print(f'Retrying casefiles call')
            casefiles = self._api_call(f'{self.base_url}/casefiles/public')
        for case in casefiles['casefiles']:
            existing_event = self.misp.search(value=f'%XForce-ID = {case["caseFileID"]}%', type_attribute='comment')
            if len(existing_event) > 0:
                print(f'Event already created: {case["title"]}')
                continue
            event = MISPEvent()
            event.info = case['title']
            event.add_attribute('comment', f'XForce-ID = {case["caseFileID"]}')
            print(f'Found case {case["title"]}')
            x = 0
            atta = self._api_call(f'{self.base_url}/casefiles/{case["caseFileID"]}/attachments')
            while 'status_code' in atta:
                x = x + 1
                print(f'Retrying attachments call for the {x} time')
                atta = self._api_call(f'{self.base_url}/casefiles/{case["caseFileID"]}/attachments')
                if 'status_code' not in atta:
                    break
                if x == 5:
                    print(f'Giving up on that case')
                    break
            if 'attachments' not in atta:
                continue
            for att in atta['attachments']:
                try:
                    if att['report']['type'] == 'IP':
                        event.add_attribute('ip-dst', att['report']['title'])
                    elif att['report']['type'] == 'VUL':
                        event.add_attribute('vulnerability', att['report']['title'])
                    elif att['report']['type'] == 'MAL':
                        if 'hash_type' in att['report']:
                            if att['report']['hash_type'] == 'md5':
                                event.add_attribute('md5', att['report']['title'])
                            elif att['report']['hash_type'] == 'MD5':
                                event.add_attribute('md5', att['report']['title'])
                            elif att['report']['hash_type'] == 'sha1':
                                event.add_attribute('sha1', att['report']['title'])
                            elif att['report']['hash_type'] == 'SHA1':
                                event.add_attribute('sha1', att['report']['title'])
                            elif att['report']['hash_type'] == 'SHA256':
                                event.add_attribute('sha256', att['report']['title'])
                            elif att['report']['hash_type'] == 'sha256':
                                event.add_attribute('sha256', att['report']['title'])
                            else:
                                print(f'Add support for {att["report"]["hash_type"]} hash type')
                        else:
                            if len(att['report']['title']) == 32:
                                event.add_attribute('md5', att['report']['title'])
                            elif len(att['report']['title']) == 40:
                                event.add_attribute('sha1', att['report']['title'])
                            elif len(att['report']['title']) == 64:
                                event.add_attribute('sha256', att['report']['title'])
                            else:
                                print(f'Don\'t recognize this checksum: {att["report"]["title"]}')
                    elif att['report']['type'] == 'URL':
                        event.add_attribute('url', att['report']['title'])
                    elif att['report']['type'] == 'BOT':
                        gal = self._api_call(f'{self.misp_url}/galaxies', misp=True, post=True, postdata={'value': att['report']['title']})
                        if len(gal) != 0:
                            for g in gal:
                                event.add_galaxy(**g['Galaxy'])
                    else:
                        print(f'Add support for attribute type: {att["report"]["type"]}')
                except KeyError:
                    if 'file' in att:
                        file_object = MISPObject('file')
                        if 'md5checksum' in att:
                            file_object.add_attribute('md5', att['md5checksum'])
                        if 'sha256' in att:
                            file_object.add_attribute('sha256', att['sha256'])
                        if 'aliasFileName' in att:
                            file_object.add_attribute('filename', att['aliasFileName'])
                        if 'content_type' in att['file']:
                            try:
                                file_object.add_attribute('mime-type', att['file']['content_type'])
                            except:
                                pass
                        print(f'Adding file object to event')
                        event.add_object(**file_object)
                    else:
                        print(f'{att}')
            self.misp.add_event(event)

    def _api_call(self, url, misp=False, post=False, postdata={}):
        try:
            if misp:
                if post:
                    result = requests.post(url, verify=False, headers={'Authorization': self._misp_apikey, 'Accept': 'application/json'}, data=postdata)
                else:
                    result = requests.get(url, verify=False, headers={'Authorization': self._misp_apikey, 'Accept': 'application/json'})
            else:
                result = requests.get(url, auth=HTTPBasicAuth(self._apikey, self._apipassword))
        except Exception as e:
            return
        status_code = result.status_code
        if status_code != 200:
            print(f'{status_code} Request failed')
            return {'status_code': status_code}
        return result.json()

if __name__ == '__main__':
    key = os.environ['XFORCE_API_KEY']
    password = os.environ['XFORCE_API_PASS']
    mispkey = os.environ['MISP_AUTH_KEY']
    mispurl = os.environ['MISP_URL']
    parser = XforceExchange(key, password, mispkey, mispurl)
    parser.get_events()

