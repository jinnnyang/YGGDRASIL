# Exchange Integration

Relevant source files

* [freqtrade/exchange/\_\_init\_\_.py](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/exchange/__init__.py)
* [freqtrade/exchange/binance.py](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/exchange/binance.py)
* [freqtrade/exchange/exchange.py](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/exchange/exchange.py)
* [freqtrade/exchange/kraken.py](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/exchange/kraken.py)
* [freqtrade/freqtradebot.py](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/freqtradebot.py)
* [tests/conftest.py](https://github.com/freqtrade/freqtrade/blob/8e91fea1/tests/conftest.py)
* [tests/exchange/test\_binance.py](https://github.com/freqtrade/freqtrade/blob/8e91fea1/tests/exchange/test_binance.py)
* [tests/exchange/test\_exchange.py](https://github.com/freqtrade/freqtrade/blob/8e91fea1/tests/exchange/test_exchange.py)
* [tests/exchange/test\_kraken.py](https://github.com/freqtrade/freqtrade/blob/8e91fea1/tests/exchange/test_kraken.py)

## Purpose and Scope

The Exchange Integration layer provides a unified interface for interacting with cryptocurrency exchanges through the CCXT library. This abstraction layer enables Freqtrade to support 20+ exchanges with consistent behavior while accommodating exchange-specific requirements and quirks.

This document covers the exchange abstraction layer, CCXT integration, exchange-specific implementations, order execution, and market data fetching. For information about how the core trading bot orchestrates exchange operations, see [FreqtradeBot Core](/freqtrade/freqtrade/2.1-freqtradebot-core). For strategy-level data access patterns, see [Data Provider and Market Data Flow](/freqtrade/freqtrade/2.4-data-provider-and-market-data-flow).

---

## Architecture Overview

The exchange system is built on a hierarchical architecture with a base class providing common functionality and exchange-specific subclasses handling unique requirements.

```mermaid
flowchart TD

FreqtradeBot["FreqtradeBot<br>freqtradebot.py"]
ExchangeResolver["ExchangeResolver<br>resolvers/exchange_resolver.py"]
ExchangeBase["Exchange (Base Class)<br>exchange/exchange.py"]
Binance["Binance<br>exchange/binance.py"]
Kraken["Kraken<br>exchange/kraken.py"]
Bybit["Bybit<br>exchange/bybit.py"]
OtherExchanges["20+ Other Exchanges"]
CCXTSync["ccxt (sync)<br>ccxt module"]
CCXTPro["ccxt.pro (async)<br>ccxt_pro module"]
ExchangeWS["ExchangeWS<br>exchange/exchange_ws.py"]
BinanceAPI["Binance API"]
KrakenAPI["Kraken API"]
OtherAPIs["Other Exchange APIs"]

FreqtradeBot --> ExchangeResolver
ExchangeBase --> Binance
ExchangeBase --> Kraken
ExchangeBase --> Bybit
ExchangeBase --> OtherExchanges
Binance --> CCXTSync
Binance --> CCXTPro
Binance --> ExchangeWS
CCXTSync --> BinanceAPI
CCXTPro --> KrakenAPI
ExchangeWS --> BinanceAPI
CCXTPro --> OtherAPIs

subgraph subGraph4 ["External APIs"]
    BinanceAPI
    KrakenAPI
    OtherAPIs
end

subgraph subGraph3 ["CCXT Library Layer"]
    CCXTSync
    CCXTPro
    ExchangeWS
end

subgraph subGraph2 ["Exchange Implementations"]
    Binance
    Kraken
    Bybit
    OtherExchanges
end

subgraph subGraph1 ["Exchange Abstraction Layer"]
    ExchangeResolver
    ExchangeBase
    ExchangeResolver --> ExchangeBase
end

subgraph subGraph0 ["Core Bot Layer"]
    FreqtradeBot
end
```

**Sources:** [freqtrade/exchange/exchange.py119-478](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/exchange/exchange.py#L119-L478) [freqtrade/freqtradebot.py96-98](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/freqtradebot.py#L96-L98) [freqtrade/exchange/\_\_init\_\_.py1-51](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/exchange/__init__.py#L1-L51)

---

## Exchange Base Class Structure

The `Exchange` class provides the core abstraction layer for all exchange interactions. It manages CCXT instances, market data, caching, and provides a consistent API regardless of the underlying exchange.

### Class Initialization and Configuration

The Exchange class maintains multiple CCXT instances and configuration structures:

```mermaid
flowchart TD

Init["init()"]
APISync["self._api<br>(ccxt.Exchange)"]
APIAsync["self._api_async<br>(ccxt_pro.Exchange)"]
APIWS["self._ws_async<br>(ccxt_pro.Exchange)"]
ExWS["self._exchange_ws<br>(ExchangeWS)"]
Markets["self._markets<br>(dict)"]
Fees["self._trading_fees<br>(dict)"]
Tiers["self._leverage_tiers<br>(dict)"]
KlinesCache["self._klines<br>(dict[PairWithTimeframe, DataFrame])"]
TradesCache["self._trades<br>(dict[PairWithTimeframe, DataFrame])"]
TickersCache["self._fetch_tickers_cache<br>(FtTTLCache)"]
RateCache["self._entry_rate_cache<br>self._exit_rate_cache<br>(FtTTLCache)"]


subgraph subGraph0 ["Exchange Instance Components"]
    Init
    APISync
    APIAsync
    APIWS
    ExWS
    Markets
    Fees
    Tiers
    KlinesCache
    TradesCache
    TickersCache
    RateCache
    Init --> APISync
    Init --> APIAsync
    Init --> APIWS
    Init --> ExWS
    Init --> Markets
    Init --> Fees
    Init --> Tiers
    Init --> KlinesCache
    Init --> TradesCache
    Init --> TickersCache
    Init --> RateCache
end
```

**Sources:** [freqtrade/exchange/exchange.py179-304](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/exchange/exchange.py#L179-L304) [freqtrade/exchange/exchange.py360-410](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/exchange/exchange.py#L360-L410)

### FtHas Capabilities System

The `_ft_has` dictionary defines exchange-specific capabilities and behaviors. Exchanges inherit defaults and override specific features:

| Capability | Type | Default | Description |
| --- | --- | --- | --- |
| `stoploss_on_exchange` | bool | False | Exchange supports native stoploss orders |
| `stop_price_param` | str | "stopLossPrice" | Parameter name for stop price in orders |
| `order_time_in_force` | list | ["GTC"] | Supported time-in-force values |
| `ohlcv_partial_candle` | bool | True | Current candle is incomplete |
| `trades_pagination` | str | "time" | Pagination type: "time" or "id" |
| `trades_has_history` | bool | False | Exchange provides historical trades |
| `ws_enabled` | bool | False | WebSocket support tested and enabled |
| `ccxt_futures_name` | str | "swap" | CCXT futures market type name |
| `needs_trading_fees` | bool | False | Requires fetching trading fees on startup |

**Sources:** [freqtrade/exchange/exchange.py129-170](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/exchange/exchange.py#L129-L170)

---

## Exchange-Specific Implementations

Exchange subclasses override base class methods to handle exchange-specific behavior, parameters, and API quirks.

### Binance Exchange Implementation

Binance is one of the most feature-complete implementations with futures support and optimized data fetching:

```mermaid
flowchart TD

BinanceClass["Binance Class<br>exchange/binance.py"]
FtHas["_ft_has overrides:<br>- stoploss_on_exchange: True<br>- trades_has_history: True<br>- ws_enabled: True<br>- has_delisting: True"]
FtHasFutures["_ft_has_futures overrides:<br>- stoploss_blocks_assets: False<br>- floor_leverage: True<br>- proxy_coin_mapping"]
GetTickers["get_tickers()<br>Merges bid/ask for futures"]
AdditionalInit["additional_exchange_init()<br>- Check position side<br>- Check multi-asset margin"]
HistOHLCV["get_historic_ohlcv()<br>- Fast pair detection<br>- data.binance.vision download"]
FastOHLCV["get_historic_ohlcv_fast()<br>download_archive_ohlcv()"]
FundingFee["funding_fee_cutoff()<br>15-second cutoff logic"]
LiqPrice["dry_run_liquidation_price()<br>Binance formula implementation"]
LevTiers["load_leverage_tiers()<br>JSON file or API"]


subgraph subGraph0 ["Binance-Specific Features"]
    BinanceClass
    FtHas
    FtHasFutures
    GetTickers
    AdditionalInit
    HistOHLCV
    FastOHLCV
    FundingFee
    LiqPrice
    LevTiers
    BinanceClass --> FtHas
    BinanceClass --> FtHasFutures
    BinanceClass --> GetTickers
    BinanceClass --> AdditionalInit
    BinanceClass --> HistOHLCV
    HistOHLCV --> FastOHLCV
    BinanceClass --> FundingFee
    BinanceClass --> LiqPrice
    BinanceClass --> LevTiers
end
```

**Key Binance Overrides:**

1. **get\_tickers()** [exchange/binance.py96-109](https://github.com/freqtrade/freqtrade/blob/8e91fea1/exchange/binance.py#L96-L109): Fetches both tickers and bid/ask data for futures, merging them since Binance futures tickers lack bid/ask.
2. **additional\_exchange\_init()** [exchange/binance.py112-148](https://github.com/freqtrade/freqtrade/blob/8e91fea1/exchange/binance.py#L112-L148): Validates that hedge mode and multi-asset margin are disabled, as Freqtrade doesn't support these.
3. **get\_historic\_ohlcv()** [exchange/binance.py150-213](https://github.com/freqtrade/freqtrade/blob/8e91fea1/exchange/binance.py#L150-L213): Detects new pairs by fetching the first available candle and downloads bulk data from data.binance.vision for efficiency.
4. **dry\_run\_liquidation\_price()** [exchange/binance.py292-374](https://github.com/freqtrade/freqtrade/blob/8e91fea1/exchange/binance.py#L292-L374): Implements Binance-specific liquidation price formula considering maintenance margin and cross-margin positions.

**Sources:** [freqtrade/exchange/binance.py30-439](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/exchange/binance.py#L30-L439)

### Kraken Exchange Implementation

Kraken requires special handling for balance management and parameter formatting:

```mermaid
flowchart TD

KrakenClass["Kraken Class<br>exchange/kraken.py"]
Params["_params:<br>trading_agreement: 'agree'"]
FtHas["_ft_has overrides:<br>- stoploss_on_exchange: True<br>- ohlcv_has_history: False<br>- trades_has_history: True"]
MarketTradable["market_is_tradable()<br>Exclude darkpool pairs"]
ConsolidateBalance["consolidate_balances()<br>Merge .F reward balances"]
GetBalances["get_balances()<br>- Fetch balance<br>- Consolidate .F<br>- Calculate 'used' from orders"]
SetLeverage["_set_leverage()<br>No-op (leverage in order)"]
GetParams["_get_params()<br>Add leverage to order params"]
CalcFunding["calculate_funding_fees()<br>Requires time_in_ratio param"]
TradePagination["_get_trade_pagination_next_value()<br>Extract from info array"]
ValidTradePagID["_valid_trade_pagination_id()<br>Check ID length >= 19"]


subgraph subGraph0 ["Kraken-Specific Features"]
    KrakenClass
    Params
    FtHas
    MarketTradable
    ConsolidateBalance
    GetBalances
    SetLeverage
    GetParams
    CalcFunding
    TradePagination
    ValidTradePagID
    KrakenClass --> Params
    KrakenClass --> FtHas
    KrakenClass --> MarketTradable
    KrakenClass --> ConsolidateBalance
    GetBalances --> ConsolidateBalance
    KrakenClass --> GetBalances
    KrakenClass --> SetLeverage
    KrakenClass --> GetParams
    KrakenClass --> CalcFunding
    KrakenClass --> TradePagination
    KrakenClass --> ValidTradePagID
end
```

**Key Kraken Overrides:**

1. **consolidate\_balances()** [exchange/kraken.py55-70](https://github.com/freqtrade/freqtrade/blob/8e91fea1/exchange/kraken.py#L55-L70): Merges balances with `.F` suffix (rewards balances) into base currency totals.
2. **get\_balances()** [exchange/kraken.py72-115](https://github.com/freqtrade/freqtrade/blob/8e91fea1/exchange/kraken.py#L72-L115): Manually calculates `used` balance by summing open order amounts since Kraken doesn't provide this directly.
3. **\_get\_params()** [exchange/kraken.py129-149](https://github.com/freqtrade/freqtrade/blob/8e91fea1/exchange/kraken.py#L129-L149): Adds leverage to order parameters and handles `PO` (post-only) as `postOnly` parameter.
4. **\_valid\_trade\_pagination\_id()** [exchange/kraken.py199-209](https://github.com/freqtrade/freqtrade/blob/8e91fea1/exchange/kraken.py#L199-L209): Validates that trade pagination IDs are proper timestamps (>= 19 characters) to work around Kraken API issues.

**Sources:** [freqtrade/exchange/kraken.py21-210](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/exchange/kraken.py#L21-L210)

---

## Initialization and Resolution Flow

The exchange initialization process involves configuration loading, exchange resolution, market loading, and validation:

```mermaid
sequenceDiagram
  participant FreqtradeBot
  participant ExchangeResolver
  participant Exchange (Base)
  participant Exchange Subclass
  participant (e.g., Binance)
  participant CCXT Library
  participant Exchange API

  FreqtradeBot->>ExchangeResolver: load_exchange(config)
  ExchangeResolver->>ExchangeResolver: Determine exchange name
  loop [Exchange has subclass]
    ExchangeResolver->>Exchange Subclass: __init__(config)
    Exchange Subclass->>Exchange (Base): super().__init__(config)
    ExchangeResolver->>Exchange (Base): __init__(config)
    Exchange (Base)->>Exchange (Base): build_ft_has()
    Exchange (Base)->>Exchange (Base): Merge _ft_has defaults
    Exchange (Base)->>CCXT Library: _init_ccxt(sync=True)
    Exchange (Base)->>Exchange (Base): Create sync ccxt instance
    Exchange (Base)->>CCXT Library: _init_ccxt(sync=False)
    Exchange (Base)->>Exchange (Base): Create async ccxt instance
    Exchange (Base)->>Exchange (Base): _init_ccxt(ws=True)
    Exchange (Base)->>Exchange (Base): Create ExchangeWS instance
    Exchange (Base)->>CCXT Library: reload_markets(force=True)
    CCXT Library->>Exchange API: _api_async.load_markets()
    Exchange API-->>CCXT Library: GET /markets
    CCXT Library-->>Exchange (Base): Market data
    Exchange (Base)->>Exchange (Base): Markets dict
    Exchange (Base)->>CCXT Library: Assign self._markets
    CCXT Library->>Exchange API: fetch_trading_fees()
    Exchange API-->>CCXT Library: GET /trading_fees
    CCXT Library-->>Exchange (Base): Fee data
    Exchange (Base)->>Exchange (Base): Trading fees
    Exchange Subclass->>Exchange Subclass: fill_leverage_tiers()
    Exchange Subclass->>CCXT Library: load_leverage_tiers()
    CCXT Library->>Exchange API: fetch_leverage_tiers()
    Exchange API-->>CCXT Library: GET /leverage_tiers
  end
  Exchange (Base)->>Exchange (Base): Tier data
  Exchange (Base)->>Exchange (Base): validate_config(config)
  Exchange Subclass->>Exchange Subclass: Validate timeframes, pairs, order types
  Exchange Subclass->>Exchange API: additional_exchange_init()
  Exchange (Base)-->>ExchangeResolver: Exchange-specific validation calls
  ExchangeResolver-->>FreqtradeBot: Exchange instance
```

**Sources:** [freqtrade/freqtradebot.py96-98](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/freqtradebot.py#L96-L98) [freqtrade/exchange/exchange.py179-304](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/exchange/exchange.py#L179-L304) [freqtrade/exchange/exchange.py690-726](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/exchange/exchange.py#L690-L726)

---

## Order Execution Flow

The exchange layer provides methods for creating, fetching, and canceling orders with built-in retry logic and error handling:

```mermaid
sequenceDiagram
  participant FreqtradeBot
  participant Exchange
  participant @retrier decorator
  participant CCXT API
  participant Exchange API

  FreqtradeBot->>Exchange: create_order(pair, ordertype,
  Exchange->>Exchange: side, amount, rate)
  Exchange->>Exchange: Validate order parameters
  Exchange->>Exchange: _get_params()
  Exchange->>Exchange: Build exchange-specific params
  loop [Success]
    Exchange->>Exchange: amount_to_precision()
    Exchange->>Exchange: price_to_precision()
    Exchange->>Exchange: create_dry_run_order()
    Exchange-->>FreqtradeBot: Generate order_id
    Exchange->>@retrier decorator: Store in _dry_run_open_orders
    @retrier decorator->>CCXT API: Order dict
    CCXT API->>Exchange API: _create_order() with @retrier
    Exchange API-->>CCXT API: create_order(symbol, type, side,
    CCXT API-->>@retrier decorator: amount, price, params)
    @retrier decorator->>Exchange: POST /order
    @retrier decorator->>Exchange: Order response
    @retrier decorator-->>Exchange: Order dict
    CCXT API-->>@retrier decorator: _order_contracts_to_amount()
    @retrier decorator->>@retrier decorator: _log_exchange_response()
    note over @retrier decorator: Retry loop continues
    CCXT API-->>@retrier decorator: Processed order
    @retrier decorator-->>Exchange: ccxt.NetworkError /
    @retrier decorator-->>Exchange: ccxt.OperationFailed
    Exchange-->>FreqtradeBot: Wait with exponential backoff
  end
```

**Key Components:**

1. **create\_order()** [exchange/exchange.py1406-1499](https://github.com/freqtrade/freqtrade/blob/8e91fea1/exchange/exchange.py#L1406-L1499): Main order creation method that validates parameters, applies precision, and delegates to CCXT.
2. **@retrier decorator** [exchange/common.py66-150](https://github.com/freqtrade/freqtrade/blob/8e91fea1/exchange/common.py#L66-L150): Wraps API calls with exponential backoff retry logic for temporary errors.
3. **\_get\_params()** [exchange/exchange.py1194-1221](https://github.com/freqtrade/freqtrade/blob/8e91fea1/exchange/exchange.py#L1194-L1221): Builds exchange-specific parameters including leverage, reduceOnly flags, and time-in-force settings.
4. **Precision methods** [exchange/exchange.py1316-1383](https://github.com/freqtrade/freqtrade/blob/8e91fea1/exchange/exchange.py#L1316-L1383): Convert amounts and prices to exchange-required precision using CCXT precision mode (DECIMAL\_PLACES or TICK\_SIZE).

**Sources:** [freqtrade/exchange/exchange.py1406-1499](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/exchange/exchange.py#L1406-L1499) [freqtrade/exchange/common.py66-150](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/exchange/common.py#L66-L150)

---

## Market Data Fetching

The exchange layer fetches various types of market data with caching and refresh mechanisms:

### OHLCV Data Flow

**OHLCV Caching Strategy:**

1. **Per-pair/timeframe cache**: `_klines` dictionary stores DataFrames indexed by `(pair, timeframe)` tuple [exchange/exchange.py242](https://github.com/freqtrade/freqtrade/blob/8e91fea1/exchange/exchange.py#L242-L242)
2. **Expiring cache**: `PeriodicCache` with TTL based on timeframe duration prevents fetching incomplete candles repeatedly [exchange/exchange.py243](https://github.com/freqtrade/freqtrade/blob/8e91fea1/exchange/exchange.py#L243-L243)
3. **Partial candle handling**: The `ohlcv_partial_candle` capability determines whether the most recent candle should be dropped or kept [exchange/exchange.py263](https://github.com/freqtrade/freqtrade/blob/8e91fea1/exchange/exchange.py#L263-L263)

**Sources:** [freqtrade/exchange/exchange.py1865-2055](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/exchange/exchange.py#L1865-L2055) [freqtrade/exchange/exchange.py2213-2329](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/exchange/exchange.py#L2213-L2329)

### Ticker and Order Book Data

```mermaid
flowchart TD

GetTickers["get_tickers(symbols)"]
FetchTickers["fetch_tickers()"]
TickerCache["_fetch_tickers_cache<br>FtTTLCache<br>TTL: 10 minutes"]
FetchL2["fetch_l2_order_book(pair, limit)"]
FetchBidsAsks["fetch_bids_asks(symbols)"]
GetRates["get_rates(pair, refresh)"]
GetEntryRate["get_entry_rate()"]
GetExitRate["get_exit_rate()"]
EntryCache["_entry_rate_cache<br>TTL: 300s"]
ExitCache["_exit_rate_cache<br>TTL: 300s"]

GetRates --> FetchTickers
GetRates --> FetchL2

subgraph subGraph2 ["Rate Calculation"]
    GetRates
    GetEntryRate
    GetExitRate
    EntryCache
    ExitCache
    GetRates --> EntryCache
    GetRates --> ExitCache
    GetEntryRate --> GetRates
    GetExitRate --> GetRates
end

subgraph subGraph1 ["Order Book Methods"]
    FetchL2
    FetchBidsAsks
end

subgraph subGraph0 ["Ticker Methods"]
    GetTickers
    FetchTickers
    TickerCache
    GetTickers --> TickerCache
    TickerCache --> FetchTickers
    FetchTickers --> TickerCache
end
```

**Rate Caching:**

* Entry and exit rates are cached for 300 seconds to reduce API calls during RPC operations [exchange/exchange.py238-239](https://github.com/freqtrade/freqtrade/blob/8e91fea1/exchange/exchange.py#L238-L239)
* Ticker cache has 10-minute TTL and is used for portfolio valuation [exchange/exchange.py233](https://github.com/freqtrade/freqtrade/blob/8e91fea1/exchange/exchange.py#L233-L233)

**Sources:** [freqtrade/exchange/exchange.py1623-1738](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/exchange/exchange.py#L1623-L1738) [freqtrade/exchange/exchange.py2450-2644](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/exchange/exchange.py#L2450-L2644)

---

## Configuration and Validation

The exchange validates configuration on initialization and provides methods to check compatibility:

### Configuration Structure

```mermaid
flowchart TD

ExchangeConf["exchange:<br>- name<br>- key/secret/password<br>- ccxt_config<br>- ccxt_async_config<br>- enable_ws<br>- markets_refresh_interval"]
TradingMode["trading_mode:<br>- spot<br>- margin<br>- futures"]
MarginMode["margin_mode:<br>- none<br>- cross<br>- isolated"]
OrderTypes["order_types:<br>- entry<br>- exit<br>- stoploss<br>- stoploss_on_exchange"]
Pricing["entry_pricing / exit_pricing:<br>- price_side<br>- price_last_balance<br>- use_order_book<br>- order_book_top"]
ValidateConfig["validate_config()"]
ValidateTF["validate_timeframes()"]
ValidateStake["validate_stakecurrency()"]
ValidateOrders["validate_ordertypes()"]
ValidateTIF["validate_order_time_in_force()"]
ValidateTradingMode["validate_trading_mode_and_margin_mode()"]
ValidatePricing["validate_pricing()"]

ExchangeConf --> ValidateConfig
TradingMode --> ValidateConfig
MarginMode --> ValidateConfig
OrderTypes --> ValidateConfig
Pricing --> ValidateConfig

subgraph subGraph1 ["Validation Methods"]
    ValidateConfig
    ValidateTF
    ValidateStake
    ValidateOrders
    ValidateTIF
    ValidateTradingMode
    ValidatePricing
    ValidateConfig --> ValidateTF
    ValidateConfig --> ValidateStake
    ValidateConfig --> ValidateOrders
    ValidateConfig --> ValidateTIF
    ValidateConfig --> ValidateTradingMode
    ValidateConfig --> ValidatePricing
end

subgraph subGraph0 ["Exchange Configuration"]
    ExchangeConf
    TradingMode
    MarginMode
    OrderTypes
    Pricing
end
```

**Validation Flow:**

1. **validate\_timeframes()** [exchange/exchange.py765-789](https://github.com/freqtrade/freqtrade/blob/8e91fea1/exchange/exchange.py#L765-L789): Ensures configured timeframe is supported by the exchange's CCXT implementation.
2. **validate\_stakecurrency()** [exchange/exchange.py728-746](https://github.com/freqtrade/freqtrade/blob/8e91fea1/exchange/exchange.py#L728-L746): Verifies stake currency exists as a quote currency in available markets.
3. **validate\_ordertypes()** [exchange/exchange.py791-798](https://github.com/freqtrade/freqtrade/blob/8e91fea1/exchange/exchange.py#L791-L798): Checks that configured order types (market, limit, stoploss) are supported.
4. **validate\_trading\_mode\_and\_margin\_mode()** [exchange/exchange.py864-892](https://github.com/freqtrade/freqtrade/blob/8e91fea1/exchange/exchange.py#L864-L892): Validates that the exchange supports the requested trading mode and margin mode combination via `_supported_trading_mode_margin_pairs`.
5. **validate\_pricing()** [exchange/exchange.py894-920](https://github.com/freqtrade/freqtrade/blob/8e91fea1/exchange/exchange.py#L894-L920): Ensures pricing configuration (order book usage, price side) is compatible with exchange capabilities.

**Sources:** [freqtrade/exchange/exchange.py344-359](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/exchange/exchange.py#L344-L359) [freqtrade/exchange/exchange.py728-920](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/exchange/exchange.py#L728-L920)

### Markets and Market Filters

The exchange provides methods to filter and query available markets:

| Method | Purpose | Key Filters |
| --- | --- | --- |
| `get_markets()` | Get filtered market dict | base\_currencies, quote\_currencies, spot\_only, futures\_only, tradable\_only, active\_only |
| `market_is_tradable()` | Check if market is valid for trading | Checks quote/base exist, precision valid, trading mode matches |
| `market_is_spot()` | Check if market is spot | market["spot"] == True |
| `market_is_margin()` | Check if market is margin | market["margin"] == True |
| `market_is_future()` | Check if market is futures | market[ccxt\_futures\_name] == True and type == "swap" and linear == True |

**Sources:** [freqtrade/exchange/exchange.py513-594](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/exchange/exchange.py#L513-L594)

---

## Error Handling and Retry Logic

The exchange layer implements comprehensive error handling with retry mechanisms for transient failures:

```mermaid
flowchart TD

Retrier["@retrier / @retrier_async"]
RetryConfig["Retry Configuration:<br>- API_RETRY_COUNT = 4<br>- API_FETCH_ORDER_RETRY_COUNT = 5<br>- Exponential backoff: 1s, 2s, 5s, 10s"]
BackoffCalc["calculate_backoff(retrycount, max_retries)<br>Returns: [1, 2, 5, 10, 15]"]
CCXTBase["ccxt.BaseError"]
CCXTTemp["Temporary Errors:<br>- ccxt.NetworkError<br>- ccxt.DDoSProtection<br>- ccxt.OperationFailed<br>- ccxt.ExchangeError"]
CCXTPerm["Permanent Errors:<br>- ccxt.InvalidOrder<br>- ccxt.InsufficientFunds<br>- ccxt.OrderNotFound<br>- ccxt.InvalidNonce"]
FreqExceptions["Freqtrade Exceptions:<br>- TemporaryError<br>- DDosProtection<br>- InvalidOrderException<br>- InsufficientFundsError<br>- ExchangeError"]


subgraph subGraph1 ["Retry Mechanism"]
    Retrier
    RetryConfig
    BackoffCalc
    Retrier --> RetryConfig
    Retrier --> BackoffCalc
end

subgraph subGraph0 ["Exception Hierarchy"]
    CCXTBase
    CCXTTemp
    CCXTPerm
    FreqExceptions
    CCXTBase --> CCXTTemp
    CCXTBase --> CCXTPerm
    CCXTTemp --> FreqExceptions
    CCXTPerm --> FreqExceptions
end
```

**Retry Logic Implementation:**

The `@retrier` decorator wraps exchange API calls and implements exponential backoff:

1. **Temporary errors trigger retry**: NetworkError, DDoSProtection, OperationFailed get retried up to API\_RETRY\_COUNT times [exchange/common.py69-100](https://github.com/freqtrade/freqtrade/blob/8e91fea1/exchange/common.py#L69-L100)
2. **Permanent errors raise immediately**: InvalidOrder, InsufficientFunds are re-raised as Freqtrade exceptions without retry [exchange/common.py101-137](https://github.com/freqtrade/freqtrade/blob/8e91fea1/exchange/common.py#L101-L137)
3. **Exponential backoff**: Uses `calculate_backoff()` to determine sleep duration: 1s, 2s, 5s, 10s, 15s [exchange/common.py38-63](https://github.com/freqtrade/freqtrade/blob/8e91fea1/exchange/common.py#L38-L63)
4. **Per-method retry counts**: Some methods like `fetch_order` have higher retry counts (API\_FETCH\_ORDER\_RETRY\_COUNT = 5) [exchange/common.py26](https://github.com/freqtrade/freqtrade/blob/8e91fea1/exchange/common.py#L26-L26)

**Example: Order Fetching with Retries**

```
```
@retrier
def fetch_order(self, order_id: str, pair: str) -> CcxtOrder:
    # Retries up to 5 times with exponential backoff
    # on temporary errors (NetworkError, DDoSProtection)
```
```

**Sources:** [freqtrade/exchange/common.py24-150](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/exchange/common.py#L24-L150) [freqtrade/exchange/exchange.py1534-1578](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/exchange/exchange.py#L1534-L1578)

---

## WebSocket Support

For exchanges with tested WebSocket support, Freqtrade can use real-time data streams instead of polling:

```mermaid
flowchart TD

ExchangeWSClass["ExchangeWS<br>exchange/exchange_ws.py"]
CCXTPro["ccxt.pro<br>(WebSocket support)"]
WSEnabled["_ft_has['ws_enabled'] = True"]
EnableWS["exchange.enable_ws = True<br>(config)"]
WatchOHLCV["watch_ohlcv(pair, timeframe)"]
StartWS["start()<br>Initialize WebSocket"]
Shutdown["shutdown()<br>Close connections"]
Reset["reset_connections()<br>Periodic reset"]
KlinesUpdate["_set_klines()<br>Update _klines cache"]
MessageQueue["_msg_queue<br>DataProvider messages"]

ExchangeWSClass --> WatchOHLCV
WatchOHLCV --> KlinesUpdate
ExchangeWSClass --> StartWS
ExchangeWSClass --> Shutdown
ExchangeWSClass --> Reset

subgraph subGraph2 ["Data Flow"]
    KlinesUpdate
    MessageQueue
    KlinesUpdate --> MessageQueue
end

subgraph subGraph1 ["WebSocket Operations"]
    WatchOHLCV
    StartWS
    Shutdown
    Reset
end

subgraph subGraph0 ["WebSocket Architecture"]
    ExchangeWSClass
    CCXTPro
    WSEnabled
    EnableWS
    WSEnabled --> EnableWS
    EnableWS --> ExchangeWSClass
    ExchangeWSClass --> CCXTPro
end
```

**WebSocket Initialization:**

1. Check `_ft_has["ws_enabled"]` is True for the exchange [exchange/exchange.py280](https://github.com/freqtrade/freqtrade/blob/8e91fea1/exchange/exchange.py#L280-L280)
2. Check `exchange.enable_ws` is True in config (defaults to True) [exchange/exchange.py283](https://github.com/freqtrade/freqtrade/blob/8e91fea1/exchange/exchange.py#L283-L283)
3. Create `_ws_async` CCXT instance [exchange/exchange.py286](https://github.com/freqtrade/freqtrade/blob/8e91fea1/exchange/exchange.py#L286-L286)
4. Initialize `ExchangeWS` wrapper [exchange/exchange.py287](https://github.com/freqtrade/freqtrade/blob/8e91fea1/exchange/exchange.py#L287-L287)

**WebSocket Benefits:**

* Real-time OHLCV updates without polling
* Reduced API call count and rate limit usage
* Lower latency for market data

**Supported Exchanges with WebSocket:**

* Binance (SPOT only, `ws_enabled: True`)
* Other exchanges vary by implementation

**Sources:** [freqtrade/exchange/exchange.py280-287](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/exchange/exchange.py#L280-L287) [freqtrade/exchange/exchange\_ws.py1-400](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/exchange/exchange_ws.py#L1-L400)

---

## Futures and Margin Trading Support

The exchange layer provides specialized support for leveraged trading:

### Trading Mode and Margin Mode Configuration

```mermaid
flowchart TD

TradingMode["TradingMode enum:<br>- SPOT<br>- MARGIN<br>- FUTURES"]
MarginMode["MarginMode enum:<br>- NONE<br>- CROSS<br>- ISOLATED"]
SupportedPairs["_supported_trading_mode_margin_pairs<br>List[Tuple[TradingMode, MarginMode]]"]
ContractSize["get_contract_size(pair)<br>Returns contract multiplier"]
Conversion["Contract Conversions:<br>- amount_to_contracts()<br>- contracts_to_amount()<br>- _order_contracts_to_amount()"]
Leverage["Leverage Operations:<br>- _set_leverage(leverage, pair)<br>- get_max_leverage(pair, stake)"]
LevTiers["Leverage Tiers:<br>- fill_leverage_tiers()<br>- get_maintenance_ratio_and_amt()"]
Funding["Funding Fees:<br>- get_funding_fees(pair, amount)<br>- calculate_funding_fees()"]
Liquidation["Liquidation Price:<br>- get_liquidation_price()<br>- dry_run_liquidation_price()"]
CCXTOptions["ccxt options:<br>- defaultType: 'spot'/'margin'/'swap'"]
CCXTFutures["_ft_has['ccxt_futures_name']<br>Default: 'swap'"]

SupportedPairs --> ContractSize
SupportedPairs --> Leverage
SupportedPairs --> LevTiers
SupportedPairs --> Funding
SupportedPairs --> Liquidation
TradingMode --> CCXTOptions

subgraph subGraph2 ["CCXT Configuration"]
    CCXTOptions
    CCXTFutures
    CCXTFutures --> CCXTOptions
end

subgraph subGraph1 ["Futures-Specific Features"]
    ContractSize
    Conversion
    Leverage
    LevTiers
    Funding
    Liquidation
    ContractSize --> Conversion
end

subgraph subGraph0 ["Trading Modes"]
    TradingMode
    MarginMode
    SupportedPairs
    TradingMode --> SupportedPairs
    MarginMode --> SupportedPairs
end
```

**Key Futures Methods:**

1. **Contract Size Handling** [exchange/exchange.py611-648](https://github.com/freqtrade/freqtrade/blob/8e91fea1/exchange/exchange.py#L611-L648): Futures contracts may represent multiple units of the base currency (e.g., 0.01 BTC per contract). The exchange automatically converts between contracts and amounts.
2. **Leverage Management** [exchange/exchange.py1112-1193](https://github.com/freqtrade/freqtrade/blob/8e91fea1/exchange/exchange.py#L1112-L1193): Sets leverage for the pair/position. Some exchanges set leverage per symbol (Binance), others per order (Kraken).
3. **Leverage Tiers** [exchange/exchange.py2742-2839](https://github.com/freqtrade/freqtrade/blob/8e91fea1/exchange/exchange.py#L2742-L2839): Load and query maintenance margin requirements and max leverage based on position size.
4. **Funding Fees** [exchange/exchange.py2941-3112](https://github.com/freqtrade/freqtrade/blob/8e91fea1/exchange/exchange.py#L2941-L3112): Calculate funding fee costs for futures positions using mark price and funding rate data.
5. **Liquidation Price** [exchange/exchange.py3247-3293](https://github.com/freqtrade/freqtrade/blob/8e91fea1/exchange/exchange.py#L3247-L3293): Calculate the price at which a leveraged position will be liquidated, considering margin mode and open positions.

**Sources:** [freqtrade/exchange/exchange.py611-3293](https://github.com/freqtrade/freqtrade/blob/8e91fea1/freqtrade/exchange/exchange.py#L611-L3293)

---

## Testing Infrastructure

The exchange layer includes comprehensive test coverage with both unit tests and integration tests:

### Test Organization

```mermaid
flowchart TD

TestExchange["tests/exchange/test_exchange.py<br>Base Exchange class tests"]
TestBinance["tests/exchange/test_binance.py<br>Binance-specific tests"]
TestKraken["tests/exchange/test_kraken.py<br>Kraken-specific tests"]
TestOther["tests/exchange/test_*.py<br>Other exchange tests"]
PatchExchange["patch_exchange(mocker)<br>Mock exchange initialization"]
GetPatchedExchange["get_patched_exchange(mocker, config)<br>Returns mocked Exchange instance"]
CCXTHandlers["ccxt_exceptionhandlers(mocker)<br>Test retry logic for CCXT errors"]
MockMarkets["get_markets()<br>Returns mock market data"]
UnitTests["Unit Tests:<br>- Market validation<br>- Precision handling<br>- Order parameter building<br>- Rate calculations"]
IntegrationTests["Integration Tests:<br>- CCXT compatibility<br>- API error handling<br>- Exchange-specific logic"]
LongRunTests["@pytest.mark.longrun:<br>- Live exchange connectivity<br>- Real API calls<br>- Market data fetching"]

TestExchange --> GetPatchedExchange
TestExchange --> CCXTHandlers
TestBinance --> GetPatchedExchange
TestKraken --> GetPatchedExchange
TestExchange --> UnitTests
TestExchange --> IntegrationTests
TestBinance --> IntegrationTests
TestKraken --> IntegrationTests
TestOther --> LongRunTests

subgraph subGraph2 ["Test Categories"]
    UnitTests
    IntegrationTests
    LongRunTests
end

subgraph subGraph1 ["Test Utilities (conftest.py)"]
    PatchExchange
    GetPatchedExchange
    CCXTHandlers
    MockMarkets
    GetPatchedExchange --> PatchExchange
    GetPatchedExchange --> MockMarkets
end

subgraph subGraph0 ["Test Files"]
    TestExchange
    TestBinance
    TestKraken
    TestOther
end
```

**Test Helpers:**

1. **get\_patched\_exchange()** [tests/conftest.py279-288](https://github.com/freqtrade/freqtrade/blob/8e91fea1/tests/conftest.py#L279-L288): Creates an Exchange instance with mocked CCXT API, markets, and supported modes.
2. **ccxt\_exceptionhandlers()** [tests/exchange/test\_exchange.py108-136](https://github.com/freqtrade/freqtrade/blob/8e91fea1/tests/exchange/test_exchange.py#L108-L136): Tests that methods correctly handle CCXT exceptions with retries.
3. **Mock Markets** [tests/conftest.py681-800](https://github.com/freqtrade/freqtrade/blob/8e91fea1/tests/conftest.py#L681-L800): Provides realistic market data structure for testing without API calls.

**Test Coverage:**

* **Exchange initialization**: Configuration loading, CCXT setup, market loading
* **Order operations**: Create, fetch, cancel with dry-run and live modes
* **Market data**: OHLCV, tickers, trades, order books
* **Error handling**: CCXT exception wrapping, retry logic
* **Exchange-specific**: Binance futures, Kraken balance consolidation, etc.
* **Futures features**: Leverage, liquidation prices, funding fees

**Sources:** [tests/exchange/test\_exchange.py1-2500](https://github.com/freqtrade/freqtrade/blob/8e91fea1/tests/exchange/test_exchange.py#L1-L2500) [tests/exchange/test\_binance.py1-1100](https://github.com/freqtrade/freqtrade/blob/8e91fea1/tests/exchange/test_binance.py#L1-L1100) [tests/exchange/test\_kraken.py1-292](https://github.com/freqtrade/freqtrade/blob/8e91fea1/tests/exchange/test_kraken.py#L1-L292) [tests/conftest.py238-289](https://github.com/freqtrade/freqtrade/blob/8e91fea1/tests/conftest.py#L238-L289)