List<TechLarInventoryService.ProductOption> products = TechLarInventoryController.searchProducts('Notebook');
System.debug('Produtos=' + products.size());
if (products.isEmpty()) {
    System.debug('Nenhum notebook com estoque. Rode loadMockData.apex e loadEstoqueMock.apex.');
} else {
    TechLarInventoryService.StockView stock = TechLarInventoryController.getStock(products[0].productId);
    for (TechLarInventoryService.StockLine line : stock.lines) {
        System.debug(line.lojaName + '=' + line.quantidade);
    }
}
