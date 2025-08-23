// API Configuration
const String BASE_URL = 'https://transactions-cs.vercel.app/api';

// Auth Endpoints
const String LOGIN_ENDPOINT = '/auth/login';
const String REGISTER_ENDPOINT = '/auth/register';
const String LOGOUT_ENDPOINT = '/api/auth/logout';
const String REFRESH_TOKEN_ENDPOINT = '/api/auth/refresh';
const String FORGOT_PASSWORD_ENDPOINT = '/auth/forgot-password';

// Transaction Endpoints
const String SHOW_TRANSACTION_ENDPOINT = '/transaction';
const String CREATE_TRANSACTION_ENDPOINT = '/api/transaction';
const String UPDATE_TRANSACTION_ENDPOINT = '/api/transaction'; // + /{id}
const String DELETE_TRANSACTION_ENDPOINT = '/api/transaction'; // + /{id}

// User Endpoints
const String USER_PROFILE_ENDPOINT = '/api/user/profile';
const String UPDATE_PROFILE_ENDPOINT = '/api/user/profile';

// Wallet Endpoints (if needed)
const String WALLETS_ENDPOINT = '/api/wallets';
const String CREATE_WALLET_ENDPOINT = '/api/wallet';

// API Headers
const Map<String, String> DEFAULT_HEADERS = {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
};

// API Response Status Codes
const int HTTP_OK = 200;
const int HTTP_CREATED = 201;
const int HTTP_BAD_REQUEST = 400;
const int HTTP_UNAUTHORIZED = 401;
const int HTTP_FORBIDDEN = 403;
const int HTTP_NOT_FOUND = 404;
const int HTTP_INTERNAL_SERVER_ERROR = 500;

// Timeout Configuration
const Duration API_TIMEOUT = Duration(seconds: 15);
const Duration CONNECTION_TIMEOUT = Duration(seconds: 10);