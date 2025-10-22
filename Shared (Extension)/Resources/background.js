const processedUrls = new Set();
const MAX_PROCESSED_URLS = 100;

function isSearchEngineURL(url) {
    try {
        const urlObj = new URL(url);
        const host = urlObj.hostname.toLowerCase();
        
        if (host.includes('google.')) return true;
        if (host.includes('duckduckgo.com')) return true;
        if (host.includes('bing.com')) return true;
        if (host.includes('yahoo.com') || host.includes('search.yahoo.')) return true;
        if (host.includes('ecosia.org')) return true;
        if (host.includes('startpage.com')) return true;
        
        return false;
    } catch (e) {
        return false;
    }
}

function cleanProcessedUrls() {
    if (processedUrls.size > MAX_PROCESSED_URLS) {
        const toRemove = processedUrls.size - MAX_PROCESSED_URLS;
        let count = 0;
        for (const url of processedUrls) {
            processedUrls.delete(url);
            count++;
            if (count >= toRemove) break;
        }
    }
}

async function handleNavigation(details) {
    const url = details.url;
    
    if (!url.startsWith('https://')) return;
    if (url.startsWith(browser.runtime.getURL(''))) return;
    
    if (processedUrls.has(url)) {
        console.log('Already processed:', url);
        return;
    }
    
    if (!isSearchEngineURL(url)) return;
    
    console.log('Detected search engine navigation:', url);
    
    processedUrls.add(url);
    cleanProcessedUrls();
    
    try {
        const response = await browser.runtime.sendNativeMessage('link.gulgle.Gulgle.Extension', {
            action: 'checkSearchURL',
            url: url,
            incognito: details.incognito || false
        });
        
        console.log('Native response:', response);
        
        if (response && response.type === 'redirect' && response.url) {
            console.log('Redirecting to:', response.url);
            
            processedUrls.add(response.url);
            
            browser.tabs.update(details.tabId, {
                url: response.url
            });
        }
    } catch (error) {
        console.error('Error processing search URL:', error);
    }
}

browser.webNavigation.onBeforeNavigate.addListener(
    handleNavigation,
    { url: [{ schemes: ['https'] }] }
);

browser.runtime.onMessage.addListener((request, sender, sendResponse) => {
    console.log("Received request: ", request);

    if (request.greeting === "hello")
        return Promise.resolve({ farewell: "goodbye" });
});
