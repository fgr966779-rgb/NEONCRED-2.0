/// Ukrainian electronics store database for NEONCRED price analysis.
///
/// Contains real store URLs, domains, and price reference data for
/// the Ukrainian market. All prices are in UAH.

// =============================================================================
// Store model
// =============================================================================

class UkrainianStore {
  final String id;
  final String name;
  final String domain;
  final String baseUrl;
  final String colorHex;

  const UkrainianStore({
    required this.id,
    required this.name,
    required this.domain,
    required this.baseUrl,
    this.colorHex = '#00F0FF',
  });
}

// =============================================================================
// Product listing model
// =============================================================================

class ProductListing {
  final String storeId;
  final String productName;
  final String url;
  final double priceUAH;
  final String category;

  const ProductListing({
    required this.storeId,
    required this.productName,
    required this.url,
    required this.priceUAH,
    required this.category,
  });
}

// =============================================================================
// All Ukrainian electronics stores
// =============================================================================

const ukrainianStores = <UkrainianStore>[
  UkrainianStore(id: 'rozetka', name: 'Rozetka', domain: 'rozetka.com.ua', baseUrl: 'https://rozetka.com.ua', colorHex: '#6B00FF'),
  UkrainianStore(id: 'comfy', name: 'Comfy', domain: 'comfy.ua', baseUrl: 'https://comfy.ua', colorHex: '#FF3366'),
  UkrainianStore(id: 'allo', name: 'Allo', domain: 'allo.ua', baseUrl: 'https://allo.ua', colorHex: '#00F0FF'),
  UkrainianStore(id: 'citrus', name: 'Citrus', domain: 'citrus.ua', baseUrl: 'https://citrus.ua', colorHex: '#FFD700'),
  UkrainianStore(id: 'moyo', name: 'MOYO', domain: 'moyo.ua', baseUrl: 'https://moyo.ua', colorHex: '#00FF88'),
  UkrainianStore(id: 'eldorado', name: 'Eldorado', domain: 'eldorado.ua', baseUrl: 'https://eldorado.ua', colorHex: '#FFD700'),
  UkrainianStore(id: 'foxtrot', name: 'Foxtrot', domain: 'foxtrot.com.ua', baseUrl: 'https://www.foxtrot.com.ua', colorHex: '#00F0FF'),
  UkrainianStore(id: 'click', name: 'Click', domain: 'click.ua', baseUrl: 'https://click.ua', colorHex: '#6B00FF'),
  UkrainianStore(id: 'itbox', name: 'Itbox', domain: 'itbox.ua', baseUrl: 'https://www.itbox.ua', colorHex: '#00FF88'),
  UkrainianStore(id: 'brain', name: 'Brain', domain: 'brain.com.ua', baseUrl: 'https://brain.com.ua', colorHex: '#FF3366'),
  UkrainianStore(id: 'jabko', name: 'Jabko', domain: 'jabko.ua', baseUrl: 'https://jabko.ua', colorHex: '#00F0FF'),
  UkrainianStore(id: 'elmir', name: 'Elmir', domain: 'elmir.ua', baseUrl: 'https://elmir.ua', colorHex: '#6B00FF'),
  UkrainianStore(id: 'denika', name: 'Denika', domain: 'denika.ua', baseUrl: 'https://denika.ua', colorHex: '#FFD700'),
  UkrainianStore(id: 'telemart', name: 'Telemart', domain: 'telemart.ua', baseUrl: 'https://telemart.ua', colorHex: '#00FF88'),
  UkrainianStore(id: 'kvshop', name: 'KVShop', domain: 'kvshop.com.ua', baseUrl: 'https://kvshop.com.ua', colorHex: '#00F0FF'),
  UkrainianStore(id: 'sota', name: 'Sota', domain: 'sota.store', baseUrl: 'https://sota.store', colorHex: '#6B00FF'),
  UkrainianStore(id: 'mta', name: 'MTA', domain: 'mta.ua', baseUrl: 'https://mta.ua', colorHex: '#FF3366'),
  UkrainianStore(id: 'compx', name: 'Compx', domain: 'compx.ua', baseUrl: 'https://compx.ua', colorHex: '#00FF88'),
  UkrainianStore(id: 'vodafone', name: 'Vodafone', domain: 'vodafone.ua', baseUrl: 'https://www.vodafone.ua', colorHex: '#FF3366'),
  UkrainianStore(id: 'mbuy24', name: 'MBuy24', domain: 'mbuy24.com', baseUrl: 'https://mbuy24.com', colorHex: '#FFD700'),
  UkrainianStore(id: 'game_shop', name: 'Game-Shop', domain: 'game-shop.com.ua', baseUrl: 'https://game-shop.com.ua', colorHex: '#6B00FF'),
  UkrainianStore(id: 'ktc', name: 'KTC', domain: 'ktc.ua', baseUrl: 'https://ktc.ua', colorHex: '#00F0FF'),
  UkrainianStore(id: 'tehno_bit', name: 'Tehno-Bit', domain: 'tehno-bit.com.ua', baseUrl: 'https://tehno-bit.com.ua', colorHex: '#00FF88'),
  UkrainianStore(id: 'jey_tech', name: 'Jey-Tech', domain: 'jey-tech.com.ua', baseUrl: 'https://jey-tech.com.ua', colorHex: '#FFD700'),
  UkrainianStore(id: 'chillistore', name: 'Chillistore', domain: 'chillistore.com.ua', baseUrl: 'https://chillistore.com.ua', colorHex: '#6B00FF'),
  UkrainianStore(id: 'platforma', name: 'Platforma-Ukraine', domain: 'platforma-ukraine.com.ua', baseUrl: 'https://platforma-ukraine.com.ua', colorHex: '#00F0FF'),
  UkrainianStore(id: 'justbuy', name: 'JustBuy', domain: 'justbuy.com.ua', baseUrl: 'https://justbuy.com.ua', colorHex: '#00FF88'),
  UkrainianStore(id: 'storeinua', name: 'StoreInUA', domain: 'storeinua.com', baseUrl: 'https://storeinua.com', colorHex: '#FF3366'),
  UkrainianStore(id: 'grokholsky', name: 'Grokholsky', domain: 'grokholsky.com', baseUrl: 'https://grokholsky.com', colorHex: '#FFD700'),
  UkrainianStore(id: 'istore', name: 'iStore', domain: 'istore.ua', baseUrl: 'https://www.istore.ua', colorHex: '#6B00FF'),
  UkrainianStore(id: 'retromagaz', name: 'Retromagaz', domain: 'retromagaz.com', baseUrl: 'https://retromagaz.com', colorHex: '#00F0FF'),
  UkrainianStore(id: 'tv_mir', name: 'TV-Mir', domain: 'tv-mir.com.ua', baseUrl: 'https://tv-mir.com.ua', colorHex: '#FF3366'),
  UkrainianStore(id: 'deshevle_net', name: 'Deshevle-Net', domain: 'deshevle-net.com.ua', baseUrl: 'https://deshevle-net.com.ua', colorHex: '#00FF88'),
  UkrainianStore(id: 'hotline', name: 'Hotline', domain: 'hotline.ua', baseUrl: 'https://hotline.ua', colorHex: '#FF3366'),
  UkrainianStore(id: 'eker', name: 'Eker', domain: 'eker.ua', baseUrl: 'https://eker.ua', colorHex: '#00F0FF'),
  UkrainianStore(id: 'citrus_store', name: 'Citrus Store', domain: 'citrus.ua', baseUrl: 'https://citrus.ua', colorHex: '#FFD700'),
  UkrainianStore(id: 'fotos', name: 'Fotos', domain: 'fotos.ua', baseUrl: 'https://fotos.ua', colorHex: '#6B00FF'),
  UkrainianStore(id: 'rozetka_hard', name: 'Rozetka Hard', domain: 'hard.rozetka.com.ua', baseUrl: 'https://hard.rozetka.com.ua', colorHex: '#6B00FF'),
];

// =============================================================================
// Monitor listings - real URLs from Ukrainian stores
// =============================================================================

const monitorListings = <ProductListing>[
  // ASUS monitor
  ProductListing(storeId: 'rozetka', productName: 'ASUS Monitor', url: 'https://hard.rozetka.com.ua/ua/asus-90lm0bl1-b01o71/p531506884/', priceUAH: 7499, category: 'Monitors'),
  // MSI MAG 242C
  ProductListing(storeId: 'comfy', productName: 'MSI MAG 242C', url: 'https://comfy.ua/ua/monitor-igrovij-msi-mag-242c.html', priceUAH: 8999, category: 'Monitors'),
  // Xiaomi G27i 27"
  ProductListing(storeId: 'allo', productName: 'Xiaomi G27i 27"', url: 'https://allo.ua/ru/monitory/monitor-27-xiaomi-gaming-monitor-g27i-ela5375eu-2.html', priceUAH: 9499, category: 'Monitors'),
  // ASRock CL25FFB 25"
  ProductListing(storeId: 'elmir', productName: 'ASRock CL25FFB 25"', url: 'https://elmir.ua/monitors/monitor-25-asrock-cl25ffb.html', priceUAH: 5999, category: 'Monitors'),
  ProductListing(storeId: 'denika', productName: 'ASRock CL25FFB 25"', url: 'https://denika.ua/ua/p/monitor-asrock-cl25ffb-black', priceUAH: 5899, category: 'Monitors'),
  ProductListing(storeId: 'tv_mir', productName: 'ASRock CL25FFB 25"', url: 'https://tv-mir.com.ua/ua/asrock-cl25ffb/', priceUAH: 5799, category: 'Monitors'),
  ProductListing(storeId: 'deshevle_net', productName: 'ASRock CL25FFB 24.5"', url: 'https://deshevle-net.com.ua/320290-igrovij-monitor-24-5-ips-flat-144hz-1ms-fh/', priceUAH: 5699, category: 'Monitors'),
  // Prologix GM2425HD 23.8"
  ProductListing(storeId: 'click', productName: 'Prologix GM2425HD 23.8"', url: 'https://click.ua/shop/monitor-prologix-gaming-23dot8quotation-gm2425hd-va-black-200hz-p163508', priceUAH: 5299, category: 'Monitors'),
  ProductListing(storeId: 'telemart', productName: 'Prologix GM2425HD 23.8"', url: 'https://telemart.ua/products/prologix-238-gaming-gm2425hd-black/', priceUAH: 5199, category: 'Monitors'),
  ProductListing(storeId: 'itbox', productName: 'Prologix GM2425HD 23.8"', url: 'https://www.itbox.ua/ua/product/Monitor_Prologix_GM2425HD-p1205113/', priceUAH: 5349, category: 'Monitors'),
  ProductListing(storeId: 'foxtrot', productName: 'Prologix GM2425HD 23.8"', url: 'https://www.foxtrot.com.ua/uk/shop/monitoriy-prologix-gaming-gm2425hd-black.html', priceUAH: 5499, category: 'Monitors'),
  ProductListing(storeId: 'kvshop', productName: 'Prologix GM2425HD 23.8"', url: 'https://kvshop.com.ua/monitory/prologix/prologix-gm2425hd.html', priceUAH: 5099, category: 'Monitors'),
  ProductListing(storeId: 'brain', productName: 'Prologix GM2425HD 23.8"', url: 'https://brain.com.ua/ukr/Monitor_Prologix_GM2425HD-p1292671.html', priceUAH: 5249, category: 'Monitors'),
  ProductListing(storeId: 'vodafone', productName: 'Prologix GM2425HD 23.8"', url: 'https://www.vodafone.ua/shop/ua/monitor-23-8-prologix-gaming-gm2425hd-black-189712.html', priceUAH: 5399, category: 'Monitors'),
  ProductListing(storeId: 'mbuy24', productName: 'Prologix GM2425HD 23.8"', url: 'https://mbuy24.com/ua/prod/4072385-prologix-monitor-prologix-gm2425hd.html', priceUAH: 5149, category: 'Monitors'),
  ProductListing(storeId: 'mta', productName: 'Prologix GM2425HD 23.8"', url: 'https://mta.ua/monitory/313037-monitor-prologix-gm2425hd-black-23-8', priceUAH: 5299, category: 'Monitors'),
  ProductListing(storeId: 'allo', productName: 'Prologix GM2425HD 23.8"', url: 'https://allo.ua/ru/monitory/igrovoj-monitor-23-8-prologix-gaming-gm2425hd-black.html', priceUAH: 5199, category: 'Monitors'),
  ProductListing(storeId: 'comfy', productName: 'Prologix GM2425HD 23.8"', url: 'https://comfy.ua/ua/monitor-igrovij-prologix-gm2425hd.html', priceUAH: 5349, category: 'Monitors'),
  ProductListing(storeId: 'ktc', productName: 'Prologix GM2425HD 23.8"', url: 'https://ktc.ua/goods/monitor_prologix_gm2425hd.html', priceUAH: 5099, category: 'Monitors'),
  ProductListing(storeId: 'elmir', productName: 'Prologix GM2425HD 24"', url: 'https://elmir.ua/monitors/monitor-24-prologix-gm2425hd.html', priceUAH: 5199, category: 'Monitors'),
  ProductListing(storeId: 'sota', productName: 'Prologix GM2425HD 23.8"', url: 'https://sota.store/ua/monitor-prologix-gaming-23-8-gm2425hd-va-black-200hz-ua-234220.html', priceUAH: 5249, category: 'Monitors'),
  ProductListing(storeId: 'denika', productName: 'Prologix GM2425HD 23.8"', url: 'https://denika.ua/ua/p/monitor-prologix-gm2425hd', priceUAH: 5099, category: 'Monitors'),
  ProductListing(storeId: 'compx', productName: 'Prologix GM2425HD 23.8"', url: 'https://compx.ua/monitor-prologix-238-gm2425hd-fhd-va-200hz-gm2425hd-2617691/', priceUAH: 5199, category: 'Monitors'),
  // Xiaomi G27i 27" (additional store)
  ProductListing(storeId: 'allo', productName: 'Xiaomi G27i 27"', url: 'https://allo.ua/ru/monitory/monitor-27-xiaomi-gaming-monitor-g27i-ela5375eu-2.html', priceUAH: 9499, category: 'Monitors'),
  // Prologix GM2425HD at Foxtrot (duplicate listing for price war)
  ProductListing(storeId: 'foxtrot', productName: 'Prologix GM2425HD 23.8"', url: 'https://www.foxtrot.com.ua/uk/shop/monitoriy-prologix-gaming-gm2425hd-black.html', priceUAH: 5499, category: 'Monitors'),
  // Prologix GM2425HD at Comfy (price comparison)
  ProductListing(storeId: 'comfy', productName: 'Prologix GM2425HD 23.8"', url: 'https://comfy.ua/ua/monitor-igrovij-prologix-gm2425hd.html', priceUAH: 5349, category: 'Monitors'),
  // Prologix GM2425HD at KTC
  ProductListing(storeId: 'ktc', productName: 'Prologix GM2425HD 23.8"', url: 'https://ktc.ua/goods/monitor_prologix_gm2425hd.html', priceUAH: 5099, category: 'Monitors'),
  // Prologix GM2425HD at Elmir
  ProductListing(storeId: 'elmir', productName: 'Prologix GM2425HD 24"', url: 'https://elmir.ua/monitors/monitor-24-prologix-gm2425hd.html', priceUAH: 5199, category: 'Monitors'),
  // Prologix GM2425HD at Sota
  ProductListing(storeId: 'sota', productName: 'Prologix GM2425HD 23.8"', url: 'https://sota.store/ua/monitor-prologix-gaming-23-8-gm2425hd-va-black-200hz-ua-234220.html', priceUAH: 5249, category: 'Monitors'),
  // Prologix GM2425HD at Denika
  ProductListing(storeId: 'denika', productName: 'Prologix GM2425HD 23.8"', url: 'https://denika.ua/ua/p/monitor-prologix-gm2425hd', priceUAH: 5099, category: 'Monitors'),
  // Prologix GM2425HD at Compx
  ProductListing(storeId: 'compx', productName: 'Prologix GM2425HD 23.8"', url: 'https://compx.ua/monitor-prologix-238-gm2425hd-fhd-va-200hz-gm2425hd-2617691/', priceUAH: 5199, category: 'Monitors'),
  // MSI MAG 242C at Comfy (updated URL)
  ProductListing(storeId: 'comfy', productName: 'MSI MAG 242C', url: 'https://comfy.ua/ua/monitor-igrovij-msi-mag-242c.html', priceUAH: 8999, category: 'Monitors'),
];

// =============================================================================
// PS5 listings - real URLs from Ukrainian stores
// =============================================================================

const ps5Listings = <ProductListing>[
  // PS5 Slim 1TB (Disc Edition)
  ProductListing(storeId: 'click', productName: 'PS5 Slim 1TB (Disc)', url: 'https://click.ua/shop/igrova-pristavka-sony-playstation-5-slim-ultra-hd-bluminusray-left-parenthesis1000040594right-parenthesis-p135837', priceUAH: 19999, category: 'Gaming'),
  ProductListing(storeId: 'jey_tech', productName: 'PS5 Slim Digital Edition', url: 'https://jey-tech.com.ua/igrova-prystavka-sony-playstation-5-slim-digital-edition-fortnite-cobalt-star-bundle-1tb', priceUAH: 16999, category: 'Gaming'),
  ProductListing(storeId: 'game_shop', productName: 'PS5 Slim 1TB (Disc)', url: 'https://game-shop.com.ua/ua/product/ps5-slim-white-s-blu-ray-privodom', priceUAH: 20499, category: 'Gaming'),
  ProductListing(storeId: 'jabko', productName: 'PS5 Slim 1TB (Disc)', url: 'https://jabko.ua/product/sony-playstation-5-slim-blu-ray-1tb', priceUAH: 19999, category: 'Gaming'),
  ProductListing(storeId: 'chillistore', productName: 'PS5 Slim 1TB (Disc)', url: 'https://chillistore.com.ua/uk/p/1632201821-sony-playstation-5-slim-1tb-1000040591/', priceUAH: 19499, category: 'Gaming'),
  ProductListing(storeId: 'platforma', productName: 'PS5 Slim 1TB (Disc)', url: 'https://platforma-ukraine.com.ua/igrova-pristavka-sony-playstation-5-slim-1tb', priceUAH: 19299, category: 'Gaming'),
  ProductListing(storeId: 'justbuy', productName: 'PS5 Slim 1TB (Disc)', url: 'https://justbuy.com.ua/ua/igrovi-konsoli-ta-gejming-igrovi-konsoli-sony-playstation/stacionarna-igrova-pristavka-sony-playstation-5-slim-1tb-1000040591', priceUAH: 19799, category: 'Gaming'),
  ProductListing(storeId: 'storeinua', productName: 'PS5 Slim 1TB (Disc)', url: 'https://storeinua.com/products/stacionarna-igrova-pristavka-sony-playstation-5-slim-1tb/', priceUAH: 19399, category: 'Gaming'),
  ProductListing(storeId: 'tehno_bit', productName: 'PS5 Slim 1TB (Disc)', url: 'https://tehno-bit.com.ua/ua/p2834061551-konsol-sony-playstation.html', priceUAH: 19599, category: 'Gaming'),
  ProductListing(storeId: 'grokholsky', productName: 'PS5 Slim 1TB (Disc)', url: 'https://grokholsky.com/ua/product/sony/drugaya-tehnika/konsoli/staczionarnaya-igrovaya-pristavka-sony-playstation-5-slim-1tb/', priceUAH: 19699, category: 'Gaming'),
  ProductListing(storeId: 'istore', productName: 'PS5 Slim 1TB (Disc)', url: 'https://www.istore.ua/ua/item/statsionarnaya-igrovaya-pristavka-sony-playstation-5-slim-1-tb-1000040591/', priceUAH: 19999, category: 'Gaming'),
  ProductListing(storeId: 'rozetka', productName: 'PS5 Slim', url: 'https://rozetka.com.ua/ua/515758394/p515758394/', priceUAH: 20499, category: 'Gaming'),
  ProductListing(storeId: 'citrus', productName: 'PS5 Slim Digital Edition', url: 'https://citrus.ua/igrovye-pristavki/igrovaya-konsol-sony-playstation-5-slim-digital-edition-825gb-730727.html', priceUAH: 16499, category: 'Gaming'),
  ProductListing(storeId: 'retromagaz', productName: 'PS5 Slim 1TB (Disc)', url: 'https://retromagaz.com/ru/product/konsol-sony-playstation-5-slim-blu-ray-1tb-white-noviy', priceUAH: 18999, category: 'Gaming'),
  ProductListing(storeId: 'retromagaz', productName: 'PS5 Slim Digital Edition 1TB', url: 'https://retromagaz.com/ru/product/konsol-sony-playstation-5-slim-digital-edition-1tb-0000005932-white-bu-khoroshiy', priceUAH: 14499, category: 'Gaming'),
];

// =============================================================================
// All listings combined
// =============================================================================

final allListings = <ProductListing>[...monitorListings, ...ps5Listings];

// =============================================================================
// Helper functions
// =============================================================================

/// Get all listings for a given category.
List<ProductListing> getListingsForCategory(String category) {
  return allListings.where((l) => l.category == category).toList();
}

/// Get all listings matching a product name (case-insensitive partial match).
List<ProductListing> getListingsForProduct(String productName) {
  final query = productName.toLowerCase();
  return allListings.where((l) => l.productName.toLowerCase().contains(query)).toList();
}

/// Get all stores that have listings in a given category.
List<UkrainianStore> getStoresForCategory(String category) {
  final storeIds = getListingsForCategory(category).map((l) => l.storeId).toSet();
  return ukrainianStores.where((s) => storeIds.contains(s.id)).toList();
}

/// Find the cheapest listing for a product. Returns the URL or null.
String? findCheapestListingUrl(String productName) {
  final listings = getListingsForProduct(productName);
  if (listings.isEmpty) return null;
  listings.sort((a, b) => a.priceUAH.compareTo(b.priceUAH));
  return listings.first.url;
}

/// Find the cheapest price for a product in UAH.
double findCheapestPrice(String productName) {
  final listings = getListingsForProduct(productName);
  if (listings.isEmpty) return 0.0;
  return listings.map((l) => l.priceUAH).reduce((a, b) => a < b ? a : b);
}

/// Get the store name by its ID.
String getStoreNameById(String storeId) {
  final store = ukrainianStores.where((s) => s.id == storeId).firstOrNull;
  return store?.name ?? storeId;
}

/// Get a random subset of Ukrainian store names for competitor simulation.
List<String> getRandomStoreNames(int count) {
  final names = ukrainianStores.map((s) => s.name).toList();
  names.shuffle();
  return names.take(count).toList();
}

/// Get all store names as a list.
List<String> get allStoreNames => ukrainianStores.map((s) => s.name).toList();

/// Get listings sorted by price (cheapest first).
List<ProductListing> getListingsSortedByPrice(String productName) {
  final listings = getListingsForProduct(productName);
  final sorted = List<ProductListing>.from(listings);
  sorted.sort((a, b) => a.priceUAH.compareTo(b.priceUAH));
  return sorted;
}
