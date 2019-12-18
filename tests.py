import unittest
import requests

domain = "d1r7y34e57illb.cloudfront.net/"

class Tests(unittest.TestCase):
               
    def test_200(self):
        url = f"https://{domain}"
        result = requests.get(url)
        self.assertEqual(len(result.history), 0)
        
        self.assertTrue(result.ok)
        self.assertEqual(result.url, f"https://{domain}")
        self.assertDictContainsSubset({"Server": "AmazonS3"}, result.headers)
        self.assertEqual(result.status_code, 200)
        self.assertIn("Hello World", str(result.content))
        
    def test_301_redirect_to_https(self):
        url = f"http://{domain}"
        result = requests.get(url)
        self.assertEqual(len(result.history), 1)
        
        expectedRedirectResult = result.history[0]
        self.assertTrue(expectedRedirectResult.ok)
        self.assertEqual(expectedRedirectResult.url, f"http://{domain}") 
        self.assertEqual(expectedRedirectResult.status_code, 301)
        self.assertTrue(expectedRedirectResult.is_redirect)
        self.assertTrue(expectedRedirectResult.is_permanent_redirect)
        self.assertDictContainsSubset({"Server": "CloudFront"}, expectedRedirectResult.headers)
        
        self.assertTrue(result.ok)
        self.assertEqual(result.url, f"https://{domain}")
        self.assertDictContainsSubset({"Server": "AmazonS3"}, result.headers)
        self.assertEqual(result.status_code, 200)
        self.assertIn("Hello World", str(result.content))
    
if __name__ == '__main__':
    unittest.main()