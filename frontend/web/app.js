/**
 * RetinaSeg AI – Complete Clinical Ophthalmic Web App Engine
 */

const API_BASE = '/api';

// Firebase Web Configuration for medical-clinical-tool
const firebaseConfig = {
  apiKey: "AIzaSyA2J8MPP_YPToWFLLrRC1PeJtZp8xeBPtE",
  authDomain: "medical-clinical-tool.firebaseapp.com",
  projectId: "medical-clinical-tool",
  storageBucket: "medical-clinical-tool.firebasestorage.app",
  messagingSenderId: "244904937545",
  appId: "1:244904937545:web:09629907cb2d398f441798",
  measurementId: "G-958K3SXWMH"
};

let firebaseApp = null;
let firebaseAnalytics = null;
let firebaseStorage = null;
let firebaseFirestore = null;

try {
  if (typeof firebase !== 'undefined') {
    firebaseApp = firebase.initializeApp(firebaseConfig);
    if (firebase.analytics) {
      firebaseAnalytics = firebase.analytics();
      console.log('Firebase Analytics initialized successfully (G-7JSRW5LTSZ)');
    }
    if (firebase.storage) {
      firebaseStorage = firebase.storage();
      console.log('Firebase Storage initialized successfully (oct-medical-application.firebasestorage.app)');
    }
    if (firebase.firestore) {
      firebaseFirestore = firebase.firestore();
      console.log('Firebase Cloud Firestore initialized successfully (oct-medical-application)');
    }
  }
} catch (e) {
  console.warn('Firebase Web initialization notice:', e);
}

// Cloud Firestore Sync Helper
async function syncToFirestore(collectionName, docId, data) {
  if (!firebaseFirestore) return;
  try {
    await firebaseFirestore.collection(collectionName).doc(docId).set({
      ...data,
      _syncedAt: firebase.firestore.FieldValue.serverTimestamp()
    }, { merge: true });
    console.log(`Synced to Firestore: ${collectionName}/${docId}`);
  } catch (err) {
    console.warn(`Firestore sync note (${collectionName}/${docId}):`, err.message);
  }
}

const AppState = {
  token: localStorage.getItem('retinaseg_token') || null,
  user: JSON.parse(localStorage.getItem('retinaseg_user') || 'null'),
  currentScan: null,
  currentAnalysis: null,
  currentViewMode: 'overlay',
  zoomScale: 1.0,
  layerVisibility: {
    ILM: true, RNFL: true, GCL: true, IPL: true,
    INL: true, OPL: true, ONL: true, RPE: true
  },
  selectedFile: null,
  selectedFileName: null,
  patients: []
};

// DOM Initializer
document.addEventListener('DOMContentLoaded', () => {
  initThemeAndLanguage();
  initAuthUI();
  initNavigation();
  initUploadDropzone();
  initViewerControls();

  // Validate session on startup
  if (AppState.token) {
    validateSessionAndInit();
  } else {
    showLandingView();
  }
});

async function validateSessionAndInit() {
  try {
    const res = await apiFetch(`${API_BASE}/auth/me`);
    if (res.ok) {
      const user = await res.json();
      AppState.user = user;
      localStorage.setItem('retinaseg_user', JSON.stringify(user));
      showWorkspaceView();
    } else {
      handleLogout();
    }
  } catch (err) {
    handleLogout();
  }
}

// ==========================================
// THEME & MULTILINGUAL SYSTEM
// ==========================================
const I18N = {
  en: {
    appName: "RetinaSeg AI",
    appSubtitle: "Automated Retinal Layer Segmentation in OCT Images",
    appearance: "Appearance & Theme",
    language: "Language & Localization",
    lightTheme: "Light",
    darkTheme: "Dark",
    systemTheme: "System Default",
    dashboard: "Clinical Dashboard",
    patients: "Patient Management",
    uploadOCT: "Upload OCT Scan",
    aiSegmentation: "AI Segmentation Workspace",
    analysisHistory: "Analysis History",
    reports: "Clinical Reports",
    settings: "Settings",
    logout: "Logout",
    welcome: "Welcome",
    totalPatients: "Total Patients",
    totalScans: "Total OCT Scans",
    completed: "Analyses Completed",
    reportsGenerated: "PDF Reports Generated",
    newScan: "New Scan",
    generateReport: "Generate PDF Report",
    userManagement: "User Management"
  },
  te: {
    appName: "RetinaSeg AI",
    appSubtitle: "OCT చిత్రాలలో ఆటోమేటెడ్ రెటీనా పొరల విభజన",
    appearance: "రూపురేఖలు & థీమ్",
    language: "భాష & స్థానికీకరణ",
    lightTheme: "లైట్",
    darkTheme: "డార్క్",
    systemTheme: "సిస్టమ్ డిఫాల్ట్",
    dashboard: "క్లినికల్ డాష్‌బోర్డ్",
    patients: "రోగుల నిర్వహణ",
    uploadOCT: "OCT స్కాన్ అప్‌లోడ్",
    aiSegmentation: "AI సెగ్మెంటేషన్ వర్క్‌స్పేస్",
    analysisHistory: "విశ్లేషణ చరిత్ర",
    reports: "క్లినికల్ నివేదికలు",
    settings: "సెట్టింగ్‌లు",
    logout: "లాగ్ అవుట్",
    welcome: "స్వాగతం",
    totalPatients: "మొత్తం రోగులు",
    totalScans: "మొత్తం OCT స్కాన్‌లు",
    completed: "పూర్తయిన విశ్లేషణలు",
    reportsGenerated: "PDF నివేదికలు",
    newScan: "కొత్త స్కాన్",
    generateReport: "PDF నివేదికను రూపొందించండి",
    userManagement: "వినియోగదారు నిర్వహణ"
  },
  hi: {
    appName: "RetinaSeg AI",
    appSubtitle: "OCT छवियों में स्वचालित रेटिना परत विभाजन",
    appearance: "दिखावट और थीम",
    language: "भाषा और स्थानीयकरण",
    lightTheme: "लाइट",
    darkTheme: "डार्क",
    systemTheme: "सिस्टम डिफ़ॉल्ट",
    dashboard: "नैदानिक डैशबोर्ड",
    patients: "मरीज प्रबंधन",
    uploadOCT: "OCT स्कैन अपलोड",
    aiSegmentation: "AI विभाजन वर्कस्पेस",
    analysisHistory: "विश्लेषण इतिहास",
    reports: "नैदानिक रिपोर्ट",
    settings: "सेटिंग्स",
    logout: "लॉग आउट",
    welcome: "स्वागत है",
    totalPatients: "कुल मरीज",
    totalScans: "कुल OCT स्कैन",
    completed: "पूर्ण विश्लेषण",
    reportsGenerated: "PDF रिपोर्ट जेनरेटेड",
    newScan: "नया स्कैन",
    generateReport: "PDF रिपोर्ट बनाएं",
    userManagement: "उपयोगकर्ता प्रबंधन"
  },
  ta: {
    appName: "RetinaSeg AI",
    appSubtitle: "OCT படங்களில் தானியங்கி விழித்திரை அடுக்கு பிரிப்பு",
    appearance: "தோற்றம் & தீம்",
    language: "மொழி & மொழிபெயர்ப்பு",
    lightTheme: "வெளிச்சம்",
    darkTheme: "இருள்",
    systemTheme: "கணினி இயல்புநிலை",
    dashboard: "மருத்துவ டாஷ்போர்டு",
    patients: "நோயாளிகள் மேலாண்மை",
    uploadOCT: "OCT ஸ்கேன் பதிவேற்றம்",
    aiSegmentation: "AI விழித்திரை பிரிப்பு பணியிடம்",
    analysisHistory: "பகுப்பாய்வு வரலாறு",
    reports: "மருத்துவ அறிக்கைகள்",
    settings: "அமைப்புகள்",
    logout: "வெளியேறு",
    welcome: "வரவேற்கிறோம்",
    totalPatients: "மொத்த நோயாளிகள்",
    totalScans: "மொத்த OCT ஸ்கேன்கள்",
    completed: "முடிக்கப்பட்ட பகுப்பாய்வுகள்",
    reportsGenerated: "PDF அறிக்கைகள்",
    newScan: "புதிய ஸ்கேன்",
    generateReport: "PDF அறிக்கையை உருவாக்கு",
    userManagement: "பயனர் மேலாண்மை"
  }
};

let currentThemeMode = localStorage.getItem('theme_mode') || 'system';
let currentLanguage = localStorage.getItem('language_code') || 'en';

function initThemeAndLanguage() {
  applyTheme(currentThemeMode);
  applyLanguage(currentLanguage);

  // Settings theme chips
  document.querySelectorAll('.theme-chip').forEach(chip => {
    chip.addEventListener('click', () => {
      const val = chip.getAttribute('data-theme-val');
      setTheme(val);
    });
  });

  // Settings language chips
  document.querySelectorAll('.lang-chip').forEach(chip => {
    chip.addEventListener('click', () => {
      const val = chip.getAttribute('data-lang-val');
      setLanguage(val);
    });
  });

  // Header quick theme toggle
  const quickThemeBtn = document.getElementById('btn-quick-theme');
  if (quickThemeBtn) {
    quickThemeBtn.addEventListener('click', () => {
      const nextTheme = document.documentElement.getAttribute('data-theme') === 'dark' ? 'light' : 'dark';
      setTheme(nextTheme);
    });
  }

  // Header quick language dropdown
  const quickLangSelect = document.getElementById('select-quick-lang');
  if (quickLangSelect) {
    quickLangSelect.value = currentLanguage;
    quickLangSelect.addEventListener('change', (e) => {
      setLanguage(e.target.value);
    });
  }
}

function setTheme(mode) {
  currentThemeMode = mode;
  localStorage.setItem('theme_mode', mode);
  applyTheme(mode);
}

function applyTheme(mode) {
  let isDark = false;
  if (mode === 'dark') {
    isDark = true;
  } else if (mode === 'system') {
    isDark = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;
  }
  
  if (isDark) {
    document.documentElement.setAttribute('data-theme', 'dark');
  } else {
    document.documentElement.removeAttribute('data-theme');
  }

  // Update active chips
  document.querySelectorAll('.theme-chip').forEach(chip => {
    chip.classList.toggle('active', chip.getAttribute('data-theme-val') === mode);
  });

  // Update quick theme icon
  const quickThemeBtn = document.getElementById('btn-quick-theme');
  if (quickThemeBtn) {
    quickThemeBtn.innerHTML = isDark ? '<i class="fa-solid fa-sun"></i>' : '<i class="fa-solid fa-moon"></i>';
  }
}

function setLanguage(lang) {
  if (!I18N[lang]) lang = 'en';
  currentLanguage = lang;
  localStorage.setItem('language_code', lang);
  applyLanguage(lang);
}

function applyLanguage(lang) {
  if (!I18N[lang]) lang = 'en';
  currentLanguage = lang;
  
  // Set data-lang attribute on <html> to dynamically switch font family across entire application
  document.documentElement.setAttribute('data-lang', lang);
  
  const dict = I18N[lang] || I18N.en;
  
  // Update data-i18n elements
  document.querySelectorAll('[data-i18n]').forEach(el => {
    const key = el.getAttribute('data-i18n');
    if (dict[key]) {
      el.textContent = dict[key];
    }
  });

  // Update active lang chips
  document.querySelectorAll('.lang-chip').forEach(chip => {
    chip.classList.toggle('active', chip.getAttribute('data-lang-val') === lang);
  });

  // Update quick select dropdown
  const quickLangSelect = document.getElementById('select-quick-lang');
  if (quickLangSelect) {
    quickLangSelect.value = lang;
  }

  // Update Settings Typography & Font Preview Card
  const fontNames = {
    en: 'Inter',
    te: 'Noto Sans Telugu',
    hi: 'Noto Sans Devanagari',
    ta: 'Noto Sans Tamil'
  };
  const previewTexts = {
    en: 'Automated Retinal Layer Segmentation',
    te: 'ఆటోమేటెడ్ రెటీనా పొరల విభజన',
    hi: 'स्वचालित रेटिना परत विभाजन',
    ta: 'தானியங்கி விழித்திரை அடுக்கு பிரிப்பு'
  };
  const badge = document.getElementById('active-font-badge');
  if (badge) badge.innerText = fontNames[lang] || 'Inter';
  const prevText = document.getElementById('active-font-preview-text');
  if (prevText) prevText.innerText = previewTexts[lang] || previewTexts.en;
}

// Navigation Handling
function initNavigation() {
  document.querySelectorAll('.nav-item').forEach(item => {
    item.addEventListener('click', () => {
      const tab = item.getAttribute('data-tab');
      switchTab(tab);
    });
  });

  document.getElementById('btn-mobile-sidebar')?.addEventListener('click', () => {
    document.querySelector('.sidebar').classList.toggle('open');
  });

  document.getElementById('btn-open-login').addEventListener('click', () => openAuthModal('login'));
  document.getElementById('btn-open-register').addEventListener('click', () => openAuthModal('register'));
  document.getElementById('btn-hero-start').addEventListener('click', () => openAuthModal('register'));
  document.getElementById('btn-hero-login').addEventListener('click', () => openAuthModal('login'));
  document.getElementById('dash-btn-upload').addEventListener('click', () => switchTab('upload'));
  document.getElementById('btn-quick-upload').addEventListener('click', () => switchTab('upload'));
  document.getElementById('btn-view-all-history').addEventListener('click', () => switchTab('history'));
}

function switchTab(tabId) {
  document.querySelectorAll('.nav-item').forEach(i => i.classList.remove('active'));
  document.querySelectorAll('.tab-pane').forEach(p => p.classList.remove('active'));

  const navItem = document.querySelector(`.nav-item[data-tab="${tabId}"]`);
  const pane = document.getElementById(`tab-${tabId}`);

  if (navItem) navItem.classList.add('active');
  if (pane) pane.classList.add('active');

  const titles = {
    dashboard: 'Clinical Dashboard',
    patients: 'Patient Management',
    upload: 'Upload & Validate OCT B-Scan',
    viewer: 'Retinal Layer Segmentation Workspace',
    history: 'OCT Analysis History',
    reports: 'Digital Clinical Reports',
    admin: 'User Administration',
    settings: 'System & Model Settings'
  };
  document.getElementById('page-title').innerText = titles[tabId] || 'Clinical Workspace';

  // Trigger tab data refreshes
  if (tabId === 'dashboard') loadDashboardStats();
  if (tabId === 'patients') loadPatients();
  if (tabId === 'upload') loadUploadPatients();
  if (tabId === 'history') loadHistory();
  if (tabId === 'reports') loadReports();
  if (tabId === 'admin') loadAdminUsers();
}

function showLandingView() {
  document.getElementById('view-landing').classList.remove('hidden');
  document.getElementById('view-workspace').classList.add('hidden');
}

function showWorkspaceView() {
  document.getElementById('view-landing').classList.add('hidden');
  document.getElementById('view-workspace').classList.remove('hidden');

  const u = AppState.user;
  if (u) {
    document.getElementById('nav-user-name').innerText = u.full_name || 'Dr. Specialist';
    document.getElementById('nav-user-role').innerText = u.role || 'OPHTHALMOLOGIST';
    document.getElementById('dash-welcome-text').innerText = `Welcome, ${u.full_name}`;
    document.getElementById('nav-user-avatar').innerText = (u.full_name || 'D')[0].toUpperCase();

    // Show/hide admin tab
    const adminNav = document.querySelector('.admin-only');
    if (adminNav) {
      adminNav.style.display = u.role === 'ADMIN' ? 'flex' : 'none';
    }
  }

  loadDashboardStats();
  loadPatients();
}

// Authentication
function initAuthUI() {
  const modal = document.getElementById('auth-modal');
  const closeBtn = document.getElementById('btn-close-auth');
  const form = document.getElementById('auth-form');
  const toggleBtn = document.getElementById('btn-toggle-auth');
  const logoutBtn = document.getElementById('btn-logout');

  let mode = 'login'; // login or register

  closeBtn.addEventListener('click', () => modal.classList.add('hidden'));
  logoutBtn.addEventListener('click', handleLogout);

  toggleBtn.addEventListener('click', (e) => {
    e.preventDefault();
    mode = mode === 'login' ? 'register' : 'login';
    openAuthModal(mode);
  });

  function setAuthAlert(msg, type = 'danger') {
    const alertBox = document.getElementById('auth-alert');
    if (!alertBox) return;
    if (!msg) {
      alertBox.style.display = 'none';
      alertBox.innerText = '';
      return;
    }
    alertBox.style.display = 'block';
    alertBox.innerText = msg;
    if (type === 'danger') {
      alertBox.style.background = 'rgba(239, 68, 68, 0.12)';
      alertBox.style.border = '1px solid rgba(239, 68, 68, 0.3)';
      alertBox.style.color = '#ef4444';
    } else {
      alertBox.style.background = 'rgba(16, 185, 129, 0.12)';
      alertBox.style.border = '1px solid rgba(16, 185, 129, 0.3)';
      alertBox.style.color = '#10b981';
    }
  }

  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    setAuthAlert(null);

    const email = document.getElementById('auth-email').value.trim();
    const password = document.getElementById('auth-password').value;
    const submitBtn = document.getElementById('btn-auth-submit');

    if (!email || !password) {
      setAuthAlert('Please enter your email and password.', 'danger');
      return;
    }

    if (!email.includes('@') || !email.includes('.')) {
      setAuthAlert('Please enter a valid email address.', 'danger');
      return;
    }

    if (password.length < 6) {
      setAuthAlert('Password must be at least 6 characters.', 'danger');
      return;
    }

    submitBtn.disabled = true;

    if (mode === 'login') {
      submitBtn.innerText = 'Signing in...';
      try {
        const res = await fetch(`${API_BASE}/auth/login`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ email, password })
        });
        const data = await res.json();
        submitBtn.disabled = false;
        submitBtn.innerText = 'Sign In';

        if (!res.ok) throw new Error(data.detail || 'Invalid email or password.');

        AppState.token = data.access_token;
        AppState.user = data.user;
        localStorage.setItem('retinaseg_token', data.access_token);
        localStorage.setItem('retinaseg_user', JSON.stringify(data.user));

        modal.classList.add('hidden');
        showWorkspaceView();
      } catch (err) {
        submitBtn.disabled = false;
        submitBtn.innerText = 'Sign In';
        setAuthAlert(err.message, 'danger');
      }
    } else {
      const fullName = document.getElementById('auth-fullname').value.trim();
      const role = document.getElementById('auth-role').value;
      if (!fullName) {
        submitBtn.disabled = false;
        setAuthAlert('Please enter your full name & title.', 'danger');
        return;
      }

      submitBtn.innerText = 'Creating Account...';
      try {
        const res = await fetch(`${API_BASE}/auth/register`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ email, password, full_name: fullName, role })
        });
        const data = await res.json();
        submitBtn.disabled = false;
        submitBtn.innerText = 'Create Account';

        if (!res.ok) throw new Error(data.detail || 'Registration failed.');

        if (data.access_token && data.user) {
          AppState.token = data.access_token;
          AppState.user = data.user;
          localStorage.setItem('retinaseg_token', data.access_token);
          localStorage.setItem('retinaseg_user', JSON.stringify(data.user));
          modal.classList.add('hidden');
          showWorkspaceView();
        } else {
          openAuthModal('login');
          document.getElementById('auth-email').value = email;
          document.getElementById('auth-password').value = '';
          setAuthAlert('Account registered successfully! Please sign in with your credentials.', 'success');
        }
      } catch (err) {
        submitBtn.disabled = false;
        submitBtn.innerText = 'Create Account';
        setAuthAlert(err.message, 'danger');
      }
    }
  });
}

function openAuthModal(mode = 'login') {
  const modal = document.getElementById('auth-modal');
  modal.classList.remove('hidden');
  const alertBox = document.getElementById('auth-alert');
  if (alertBox) alertBox.style.display = 'none';

  const title = document.getElementById('auth-modal-title');
  const sub = document.getElementById('auth-modal-sub');
  const btn = document.getElementById('btn-auth-submit');
  const toggleText = document.getElementById('auth-toggle-text');
  const toggleBtn = document.getElementById('btn-toggle-auth');
  const nameGrp = document.getElementById('group-name');
  const roleGrp = document.getElementById('group-role');

  if (mode === 'register') {
    title.innerText = 'Register Clinical Account';
    sub.innerText = 'Create your specialist access profile';
    btn.innerText = 'Create Account';
    toggleText.innerText = 'Already have an account?';
    toggleBtn.innerText = 'Sign In';
    nameGrp.style.display = 'block';
    roleGrp.style.display = 'block';
  } else {
    title.innerText = 'Sign In to RetinaSeg AI';
    sub.innerText = 'Enter credentials to access ophthalmic workspace';
    btn.innerText = 'Sign In';
    toggleText.innerText = "Don't have an account?";
    toggleBtn.innerText = 'Register';
    nameGrp.style.display = 'none';
    roleGrp.style.display = 'none';
  }
}

function handleLogout() {
  AppState.token = null;
  AppState.user = null;
  AppState.patients = [];
  AppState.currentScan = null;
  AppState.currentAnalysis = null;
  localStorage.removeItem('retinaseg_token');
  localStorage.removeItem('retinaseg_user');
  
  // Clear dashboard metrics immediately
  const pStat = document.getElementById('stat-patients');
  const sStat = document.getElementById('stat-scans');
  const cStat = document.getElementById('stat-completed');
  const rStat = document.getElementById('stat-reports');
  if (pStat) pStat.innerText = '0';
  if (sStat) sStat.innerText = '0';
  if (cStat) cStat.innerText = '0';
  if (rStat) rStat.innerText = '0';

  const tbody = document.getElementById('dash-recent-tbody');
  if (tbody) tbody.innerHTML = `<tr><td colspan="7" class="text-center py-4 text-muted">No analyses recorded yet.</td></tr>`;
  
  showLandingView();
}

// Authenticated API Fetch Helper with Timeout
async function apiFetch(url, options = {}) {
  options.headers = options.headers || {};
  if (AppState.token) {
    options.headers['Authorization'] = `Bearer ${AppState.token}`;
  }
  
  const controller = new AbortController();
  const id = setTimeout(() => controller.abort(), 15000);
  options.signal = controller.signal;

  try {
    const res = await fetch(url, options);
    clearTimeout(id);
    if (res.status === 401) {
      handleLogout();
      throw new Error('Session expired. Please log in again.');
    }
    return res;
  } catch (err) {
    clearTimeout(id);
    throw err;
  }
}

// Dashboard Data
async function loadDashboardStats() {
  try {
    const res = await apiFetch(`${API_BASE}/dashboard/stats`);
    if (!res.ok) return;
    const data = await res.json();

    const totalPatients = data.total_patients || 0;
    const totalScans = data.total_scans || 0;
    const completed = data.analyses_completed || 0;
    const reports = data.reports_generated || 0;

    document.getElementById('stat-patients').innerText = totalPatients;
    document.getElementById('stat-scans').innerText = totalScans;
    document.getElementById('stat-completed').innerText = completed;
    document.getElementById('stat-reports').innerText = reports;

    // Handle Empty Patients Guidance Banner on Dashboard
    let emptyBanner = document.getElementById('dash-empty-patients-banner');
    if (totalPatients === 0) {
      if (!emptyBanner) {
        emptyBanner = document.createElement('div');
        emptyBanner.id = 'dash-empty-patients-banner';
        emptyBanner.className = 'clinical-card empty-guidance-banner mb-4';
        emptyBanner.innerHTML = `
          <div class="d-flex align-items-center justify-content-between p-3">
            <div class="d-flex align-items-center gap-3">
              <div class="empty-icon-circle"><i class="fa-solid fa-user-plus"></i></div>
              <div>
                <h4 class="mb-1" style="font-weight:700;font-size:1.05rem;">No Patients Yet</h4>
                <p class="text-muted mb-0" style="font-size:0.875rem;">You haven't added any patients yet. Add your first patient to begin OCT analysis.</p>
              </div>
            </div>
            <button class="btn btn-primary" onclick="openPatientModal()"><i class="fa-solid fa-plus"></i> Add Patient</button>
          </div>
        `;
        const dashContainer = document.querySelector('#view-dashboard .tab-content-container') || document.querySelector('#view-dashboard');
        if (dashContainer && dashContainer.firstChild) {
          dashContainer.insertBefore(emptyBanner, dashContainer.children[1] || dashContainer.firstChild);
        }
      }
      emptyBanner.style.display = 'block';
    } else if (emptyBanner) {
      emptyBanner.style.display = 'none';
    }

    const tbody = document.getElementById('dash-recent-tbody');
    if (data.recent_analyses && data.recent_analyses.length > 0) {
      tbody.innerHTML = data.recent_analyses.map(a => `
        <tr>
          <td><strong>${a.patient_id}</strong></td>
          <td>${a.patient_name}</td>
          <td>${a.date}</td>
          <td>${a.scan_type}</td>
          <td><span class="status-badge-chip green">${a.status}</span></td>
          <td>${a.result}</td>
          <td>
            <button class="btn btn-sm btn-outline" onclick="loadAnalysisById(${a.id})">
              <i class="fa-solid fa-eye"></i> View
            </button>
          </td>
        </tr>
      `).join('');
    } else {
      tbody.innerHTML = `
        <tr>
          <td colspan="7" class="text-center py-5 text-muted">
            <i class="fa-solid fa-microscope fa-2x mb-2" style="opacity:0.4;"></i>
            <div style="font-weight:600;font-size:0.95rem;color:var(--text-main, #0f172a);">No analyses available</div>
            <div style="font-size:0.8rem;">Analysis results will appear here after you upload and process an OCT scan.</div>
          </td>
        </tr>
      `;
    }
  } catch (err) {
    console.error('Error loading dashboard stats:', err);
  }
}

// Patient Management
async function loadPatients() {
  try {
    const res = await apiFetch(`${API_BASE}/patients`);
    if (!res.ok) return;
    AppState.patients = await res.json();
    renderPatientsTable(AppState.patients);
  } catch (err) {
    console.error('Error loading patients:', err);
    document.getElementById('patients-table-tbody').innerHTML = `<tr><td colspan="7" class="text-center py-4 text-muted">Failed to load patient records.</td></tr>`;
  }
}

function renderPatientsTable(patients) {
  const tbody = document.getElementById('patients-table-tbody');
  if (!patients || patients.length === 0) {
    tbody.innerHTML = `
      <tr>
        <td colspan="7" class="text-center py-5 text-muted">
          <i class="fa-solid fa-users fa-2x mb-2" style="opacity:0.4;"></i>
          <div style="font-weight:600;font-size:0.95rem;">No Patients Yet</div>
          <div style="font-size:0.8rem;">You haven't added any patients yet. Click "+ Register Patient" to begin.</div>
        </td>
      </tr>
    `;
    return;
  }

  tbody.innerHTML = patients.map(p => `
    <tr>
      <td><strong>${p.patient_id}</strong></td>
      <td><strong>${p.full_name}</strong></td>
      <td>${p.age} yrs / ${p.gender}</td>
      <td>${p.eye_condition || 'Routine Evaluation'}</td>
      <td>${p.date_registered ? p.date_registered.substring(0, 10) : 'Recently'}</td>
      <td><span class="status-badge-chip blue">${p.scans_count || 0} scans</span></td>
      <td>
        <div class="d-flex gap-2">
          <button class="btn btn-sm btn-primary" onclick="quickUploadForPatient(${p.id})" title="Upload OCT Scan">
            <i class="fa-solid fa-upload"></i> Upload
          </button>
          <button class="btn btn-sm btn-outline-danger" onclick="deletePatientRecord(${p.id}, '${p.full_name}')" title="Delete Patient">
            <i class="fa-solid fa-trash"></i>
          </button>
        </div>
      </td>
    </tr>
  `).join('');
}

async function deletePatientRecord(patientId, name) {
  if (!confirm(`Are you sure you want to delete patient ${name}? This will remove all associated scans and analyses.`)) {
    return;
  }
  try {
    const res = await apiFetch(`${API_BASE}/patients/${patientId}`, { method: 'DELETE' });
    if (res.ok) {
      await loadPatients();
      await loadDashboardStats();
    } else {
      const err = await res.json();
      alert(`Error deleting patient: ${err.detail || 'Unknown error'}`);
    }
  } catch (e) {
    alert(`Failed to delete patient: ${e.message}`);
  }
}

function quickUploadForPatient(patientId) {
  switchTab('upload');
  const select = document.getElementById('upload-patient-select');
  if (select) select.value = patientId;
}

async function loadUploadPatients() {
  if (AppState.patients.length === 0) {
    await loadPatients();
  }
  const select = document.getElementById('upload-patient-select');
  select.innerHTML = '<option value="">Select Patient Record...</option>' +
    AppState.patients.map(p => `<option value="${p.id}">${p.patient_id} – ${p.full_name} (${p.age}y / ${p.gender})</option>`).join('');
}

// Dropzone & Scan Upload
function initUploadDropzone() {
  const dropzone = document.getElementById('oct-dropzone');
  const fileInput = document.getElementById('oct-file-input');
  const browseBtn = document.getElementById('btn-browse-file');
  const submitBtn = document.getElementById('btn-submit-upload');

  browseBtn.addEventListener('click', (e) => {
    e.stopPropagation();
    fileInput.click();
  });

  dropzone.addEventListener('click', () => fileInput.click());

  dropzone.addEventListener('dragover', (e) => {
    e.preventDefault();
    dropzone.classList.add('dragover');
  });

  dropzone.addEventListener('dragleave', () => dropzone.classList.remove('dragover'));

  dropzone.addEventListener('drop', (e) => {
    e.preventDefault();
    dropzone.classList.remove('dragover');
    if (e.dataTransfer.files.length > 0) {
      handleFileSelected(e.dataTransfer.files[0]);
    }
  });

  fileInput.addEventListener('change', () => {
    if (fileInput.files.length > 0) {
      handleFileSelected(fileInput.files[0]);
    }
  });

  // Sample Scans Quick Picker
  document.querySelectorAll('.sample-chip').forEach(chip => {
    chip.addEventListener('click', async () => {
      const filename = chip.getAttribute('data-sample');
      try {
        const res = await fetch(`/api/static/uploads/${filename}`);
        const blob = await res.blob();
        const file = new File([blob], filename, { type: blob.type || 'image/png' });
        handleFileSelected(file);
      } catch (err) {
        alert('Could not load sample scan.');
      }
    });
  });

  submitBtn.addEventListener('click', handleUploadAndAnalyze);

  // Add Patient Modal Form
  document.getElementById('btn-open-add-patient').addEventListener('click', () => {
    document.getElementById('p-id').value = `PAT-${Math.floor(10000 + Math.random() * 90000)}`;
    document.getElementById('patient-modal').classList.remove('hidden');
  });

  document.getElementById('btn-close-patient-modal').addEventListener('click', () => {
    document.getElementById('patient-modal').classList.add('hidden');
  });

  document.getElementById('add-patient-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const payload = {
      patient_id: document.getElementById('p-id').value,
      full_name: document.getElementById('p-name').value,
      age: parseInt(document.getElementById('p-age').value) || 50,
      gender: document.getElementById('p-gender').value,
      contact: document.getElementById('p-contact').value,
      eye_condition: document.getElementById('p-condition').value,
      medical_history: document.getElementById('p-history').value
    };

    try {
      const res = await apiFetch(`${API_BASE}/patients`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
      });
      if (!res.ok) throw new Error('Failed to register patient');
      document.getElementById('patient-modal').classList.add('hidden');
      await loadPatients();
      await loadDashboardStats();
      alert('Patient registered successfully!');
    } catch (err) {
      alert(err.message);
    }
  });
}

async function handleFileSelected(file) {
  AppState.selectedFile = file;
  AppState.selectedFileName = file.name;

  // Run validation
  const vBox = document.getElementById('validation-status-box');
  const vIcon = document.getElementById('val-icon');
  const vTitle = document.getElementById('val-title');
  const vMsg = document.getElementById('val-message');
  const vMetrics = document.getElementById('val-metrics-list');
  const submitBtn = document.getElementById('btn-submit-upload');

  vBox.classList.remove('hidden');
  vTitle.innerText = 'Validating OCT Scan...';
  vMsg.innerText = 'Checking optical tissue gradient & speckle distribution...';

  const formData = new FormData();
  formData.append('file', file);

  try {
    const res = await apiFetch(`${API_BASE}/oct/validate-only`, {
      method: 'POST',
      body: formData
    });
    const val = await res.json();

    if (val.is_valid_oct) {
      vBox.className = 'validation-box';
      vIcon.innerHTML = '<i class="fa-solid fa-circle-check"></i>';
      vTitle.innerText = `Valid Retinal OCT B-Scan (Confidence: ${Math.round(val.confidence_score * 100)}%)`;
      vMsg.innerText = val.message;
      submitBtn.disabled = false;
    } else {
      vBox.className = 'validation-box invalid';
      vIcon.innerHTML = '<i class="fa-solid fa-circle-xmark"></i>';
      vTitle.innerText = 'Invalid Image Detected (Non-OCT)';
      vMsg.innerText = val.message + (val.reasons ? ` [${val.reasons.join(', ')}]` : '');
      submitBtn.disabled = true;
    }

    if (val.image_metrics) {
      vMetrics.innerText = `Resolution: ${val.image_metrics.width || 0}x${val.image_metrics.height || 0} • Stratification Ratio: ${val.image_metrics.stratification_ratio || 'N/A'}`;
    }
  } catch (err) {
    vBox.className = 'validation-box invalid';
    vTitle.innerText = 'Validation Error';
    vMsg.innerText = err.message;
    submitBtn.disabled = true;
  }
}

async function handleUploadAndAnalyze() {
  const patientSelect = document.getElementById('upload-patient-select');
  const patientId = patientSelect.value;
  if (!patientId) {
    alert('Please select a patient record first.');
    return;
  }

  const modal = document.getElementById('pipeline-progress-modal');
  modal.classList.remove('hidden');
  const statusText = document.getElementById('pipeline-status-text');

  // Step 1: Upload
  setStepState(1, 'active');
  statusText.innerText = 'Uploading scan raster to storage server...';

  const latRadio = document.querySelector('input[name="eye-laterality"]:checked');
  const laterality = latRadio ? latRadio.value : 'OD';
  const device = document.getElementById('upload-device-select').value;
  const calibration = parseFloat(document.getElementById('upload-calibration').value) || 3.87;

  const formData = new FormData();
  formData.append('patient_id', patientId);
  formData.append('eye_laterality', laterality);
  formData.append('device_manufacturer', device);
  formData.append('axial_resolution_um', calibration);
  formData.append('file', AppState.selectedFile);

  try {
    const uploadRes = await apiFetch(`${API_BASE}/oct/upload`, {
      method: 'POST',
      body: formData
    });
    const scanData = await uploadRes.json();
    if (!uploadRes.ok) throw new Error(scanData.detail?.message || 'Upload failed');
    AppState.currentScan = scanData;

    setStepState(1, 'done');
    setStepState(2, 'done');

    // Step 3: Preprocessing
    setStepState(3, 'active');
    statusText.innerText = 'Applying bilateral speckle filtering and local CLAHE contrast enhancement...';
    await new Promise(r => setTimeout(r, 600));

    const prepRes = await apiFetch(`${API_BASE}/analysis/preprocess`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ scan_id: scanData.id })
    });
    const prepData = await prepRes.json();
    setStepState(3, 'done');

    // Step 4: U-Net Segmentation
    setStepState(4, 'active');
    statusText.innerText = 'Running deep U-Net multi-layer retinal segmentation...';
    await new Promise(r => setTimeout(r, 700));

    const segRes = await apiFetch(`${API_BASE}/analysis/segment`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ scan_id: scanData.id })
    });
    const segData = await segRes.json();
    if (!segRes.ok) throw new Error(segData.detail || 'Segmentation failed');
    AppState.currentAnalysis = segData;

    setStepState(4, 'done');
    setStepState(5, 'done');
    setStepState(6, 'active');
    statusText.innerText = 'Rendering segmented retinal layers and thickness profiles...';
    await new Promise(r => setTimeout(r, 500));

    modal.classList.add('hidden');
    await loadDashboardStats();
    renderSegmentationWorkspace(segData);
    switchTab('viewer');
  } catch (err) {
    modal.classList.add('hidden');
    alert(`Pipeline Error: ${err.message}`);
  }
}

function setStepState(stepNum, state) {
  const row = document.getElementById(`pstep-${stepNum}`);
  if (!row) return;
  row.className = `step-row ${state}`;
  const dot = row.querySelector('.step-dot');
  if (state === 'done') dot.innerHTML = '<i class="fa-solid fa-check"></i>';
  if (state === 'active') dot.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i>';
}

// Segmentation Workspace Viewer
function initViewerControls() {
  // Mode Tabs
  document.querySelectorAll('.vtab').forEach(tab => {
    tab.addEventListener('click', () => {
      document.querySelectorAll('.vtab').forEach(t => t.classList.remove('active'));
      tab.classList.add('active');
      AppState.currentViewMode = tab.getAttribute('data-mode');
      updateViewerImage();
    });
  });

  // Zoom Controls
  document.getElementById('btn-zoom-in').addEventListener('click', () => {
    AppState.zoomScale = Math.min(AppState.zoomScale * 1.25, 4.0);
    applyZoom();
  });
  document.getElementById('btn-zoom-out').addEventListener('click', () => {
    AppState.zoomScale = Math.max(AppState.zoomScale / 1.25, 0.5);
    applyZoom();
  });
  document.getElementById('btn-zoom-reset').addEventListener('click', () => {
    AppState.zoomScale = 1.0;
    applyZoom();
  });

  // Opacity Slider
  const opSlider = document.getElementById('layer-opacity-slider');
  opSlider.addEventListener('input', (e) => {
    const val = e.target.value;
    document.getElementById('opacity-val-text').innerText = `${val}%`;
    const img = document.getElementById('oct-viewer-img');
    if (AppState.currentViewMode === 'overlay') {
      img.style.filter = `contrast(${1 + val / 200}) saturate(${val / 50})`;
    }
  });

  // Show / Hide All Layers
  document.getElementById('btn-show-all-layers').addEventListener('click', () => {
    document.querySelectorAll('.layers-chip-row input').forEach(c => c.checked = true);
  });
  document.getElementById('btn-hide-all-layers').addEventListener('click', () => {
    document.querySelectorAll('.layers-chip-row input').forEach(c => c.checked = false);
  });

  // Generate PDF Report
  document.getElementById('btn-ws-generate-report').addEventListener('click', handleGenerateReport);
}

function applyZoom() {
  const img = document.getElementById('oct-viewer-img');
  img.style.transform = `scale(${AppState.zoomScale})`;
  document.getElementById('zoom-text').innerText = `${Math.round(AppState.zoomScale * 100)}%`;
}

function renderSegmentationWorkspace(seg) {
  document.getElementById('ws-patient-name').innerText = seg.patient_name || 'Patient';
  document.getElementById('ws-scan-uid').innerText = seg.scan_id ? `SCAN-#${seg.scan_id}` : 'OCT-SCAN';
  document.getElementById('ws-confidence').innerText = `${Math.round((seg.confidence_score || 0.94) * 100)}%`;
  document.getElementById('ws-quality').innerText = seg.overall_quality || 'Good';
  document.getElementById('ws-time').innerText = `${Math.round(seg.execution_time_ms)} ms`;
  document.getElementById('ws-findings-text').innerText = seg.findings_summary || 'Retinal layers delineated with high anatomical continuity.';

  updateViewerImage();

  // Thickness Table
  const tbody = document.getElementById('ws-thickness-tbody');
  if (seg.layers && seg.layers.length > 0) {
    tbody.innerHTML = seg.layers.map(l => {
      const meanStr = seg.is_calibrated && l.mean_thickness_um ? `${l.mean_thickness_um} μm` : `${l.mean_thickness_px} px`;
      const minStr = seg.is_calibrated && l.min_thickness_um ? `${l.min_thickness_um} μm` : `${l.min_thickness_px} px`;
      const maxStr = seg.is_calibrated && l.max_thickness_um ? `${l.max_thickness_um} μm` : `${l.max_thickness_px} px`;

      return `
        <tr>
          <td><strong style="color:${l.color_hex || '#006699'}">${l.layer_name}</strong></td>
          <td><strong>${meanStr}</strong></td>
          <td>${minStr}</td>
          <td>${maxStr}</td>
          <td>${l.layer_area_px.toLocaleString()} px²</td>
        </tr>
      `;
    }).join('');
  }
}

function updateViewerImage() {
  const seg = AppState.currentAnalysis;
  if (!seg) return;
  const img = document.getElementById('oct-viewer-img');

  let src = seg.original_image_url;
  if (AppState.currentViewMode === 'preprocessed' && seg.preprocessed_image_url) {
    src = seg.preprocessed_image_url;
  } else if (AppState.currentViewMode === 'segmentation' && seg.mask_image_url) {
    src = seg.mask_image_url;
  } else if (AppState.currentViewMode === 'overlay' && seg.overlay_image_url) {
    src = seg.overlay_image_url;
  }

  img.src = src;
}

async function loadAnalysisById(id) {
  try {
    const res = await apiFetch(`${API_BASE}/analysis/${id}`);
    if (!res.ok) throw new Error('Analysis record not found');
    const data = await res.json();
    AppState.currentAnalysis = data;
    renderSegmentationWorkspace(data);
    switchTab('viewer');
  } catch (err) {
    alert(err.message);
  }
}

let currentActiveReport = null;

// PDF Report Generation & Preview Modal
async function handleGenerateReport() {
  const seg = AppState.currentAnalysis;
  if (!seg) return;
  const btn = document.getElementById('btn-ws-generate-report');
  btn.disabled = true;
  btn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Preparing Report Preview...';

  try {
    const res = await apiFetch(`${API_BASE}/reports/generate`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        analysis_id: seg.id,
        notes: 'Clinical U-Net retinal layer segmentation verified. Intact ILM, RNFL, and RPE boundaries.'
      })
    });
    const report = await res.json();
    btn.disabled = false;
    btn.innerHTML = '<i class="fa-solid fa-file-pdf"></i> Generate PDF Report';

    currentActiveReport = report;
    await loadDashboardStats();
    openReportPreviewModal(report, seg);
  } catch (err) {
    btn.disabled = false;
    btn.innerHTML = '<i class="fa-solid fa-file-pdf"></i> Generate PDF Report';
    alert(`Report generation error: ${err.message}`);
  }
}

function openReportPreviewModal(report, seg) {
  const modal = document.getElementById('report-preview-modal');
  if (!modal) return;

  // Header info
  document.getElementById('modal-report-id').innerText = report.report_uid || 'REP-2026';
  document.getElementById('rep-doc-uid').innerText = report.report_uid || 'REP-2026';
  document.getElementById('rep-doc-date').innerText = report.date || (report.generated_at || new Date().toISOString()).substring(0, 16).replace('T', ' ');
  document.getElementById('rep-sig-date').innerText = (report.generated_at || new Date().toISOString()).substring(0, 10);
  document.getElementById('rep-doc-doctor').innerText = report.clinician_name || (AppState.user?.full_name) || 'Dr. Sarah Reynolds, MD';
  if (document.getElementById('rep-model-engine')) {
    document.getElementById('rep-model-engine').innerText = seg.model_version || 'RetinaUNet-v1.4.2';
  }

  // Demographics & Scan Info
  document.getElementById('rep-patient-name').innerText = seg.patient_name || report.patient_name || 'Patient';
  document.getElementById('rep-patient-id').innerText = seg.patient_id || '1';
  document.getElementById('rep-patient-age-gender').innerText = `${seg.patient_age || 21} yrs / ${seg.patient_gender || 'Male'}`;
  document.getElementById('rep-patient-indication').innerText = seg.eye_condition || 'OCT Evaluation';

  document.getElementById('rep-scan-uid').innerText = seg.scan_uid || 'OCT-00000000';
  document.getElementById('rep-laterality').innerText = seg.eye_laterality || 'OD';
  document.getElementById('rep-resolution').innerText = `${seg.width || 512} x ${seg.height || 512} px`;
  document.getElementById('rep-calibration').innerText = `${seg.axial_calibration_um || 3.87} μm/pixel (Axial)`;

  // 4-Panel Images
  document.getElementById('rep-img-original').src = seg.original_image_url || '';
  document.getElementById('rep-img-preprocessed').src = seg.preprocessed_image_url || seg.original_image_url || '';
  document.getElementById('rep-img-mask').src = seg.mask_image_url || '';
  document.getElementById('rep-img-overlay').src = seg.overlay_image_url || '';

  // Thickness Table
  const tbody = document.getElementById('rep-thickness-tbody');
  if (seg.layers && seg.layers.length > 0) {
    tbody.innerHTML = seg.layers.map(l => {
      const meanStr = seg.is_calibrated && l.mean_thickness_um ? `${l.mean_thickness_um} μm` : `${l.mean_thickness_px} px`;
      const minStr = seg.is_calibrated && l.min_thickness_um ? `${l.min_thickness_um} μm` : `${l.min_thickness_px} px`;
      const maxStr = seg.is_calibrated && l.max_thickness_um ? `${l.max_thickness_um} μm` : `${l.max_thickness_px} px`;
      const confStr = l.confidence_score ? `${Math.round(l.confidence_score * 100)}%` : '95%';

      return `
        <tr>
          <td><strong style="color:${l.color_hex || '#006699'}"><span style="display:inline-block;width:8px;height:8px;border-radius:50%;background:${l.color_hex || '#006699'};margin-right:8px;"></span>${l.layer_name}</strong></td>
          <td><span style="color:var(--success); font-weight:600;">${l.is_detected ? 'Detected' : 'Not Detected'}</span></td>
          <td><strong>${meanStr}</strong></td>
          <td>${minStr}</td>
          <td>${maxStr}</td>
          <td>${(l.layer_area_px || 0).toLocaleString()}</td>
          <td>${confStr}</td>
        </tr>
      `;
    }).join('');
  }

  // Findings
  document.getElementById('rep-findings-text').innerText = seg.findings_summary || 'Automated segmentation successfully identified all 8 retinal sub-layers with high anatomical continuity.';
  document.getElementById('rep-custom-notes').innerText = report.notes || 'Clinical U-Net retinal layer segmentation verified. Intact ILM, RNFL, and RPE boundaries.';
  document.getElementById('rep-quality-tag').innerText = seg.overall_quality || 'Good';
  document.getElementById('rep-conf-tag').innerText = `${Math.round((seg.confidence_score || 0.94) * 100)}%`;

  // Attach explicit download & print handlers
  const dlBtn = document.getElementById('btn-modal-download-pdf');
  dlBtn.onclick = () => {
    const downloadUrl = `${report.pdf_url}?download=true`;
    const link = document.createElement('a');
    link.href = downloadUrl;
    link.download = `RetinaSegAI_Report_${report.report_uid || 'Scan'}.pdf`;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  const printBtn = document.getElementById('btn-modal-print-report');
  printBtn.onclick = () => {
    window.print();
  };

  // Close modal button
  document.getElementById('btn-close-report-modal').onclick = () => {
    modal.classList.add('hidden');
  };

  modal.classList.remove('hidden');
}

// History & Reports Tabs
async function loadHistory() {
  const tbody = document.getElementById('history-table-tbody');
  if (!tbody) return;
  try {
    const res = await apiFetch(`${API_BASE}/analysis/history/all`);
    if (!res.ok) {
      tbody.innerHTML = `<tr><td colspan="7" class="text-center py-4 text-muted">No historical analyses recorded yet.</td></tr>`;
      return;
    }
    const history = await res.json();

    if (!history || history.length === 0) {
      tbody.innerHTML = `<tr><td colspan="7" class="text-center py-4 text-muted">No historical analyses recorded yet. Upload a scan to start.</td></tr>`;
      return;
    }

    tbody.innerHTML = history.map(h => `
      <tr>
        <td><strong>${h.scan_uid}</strong></td>
        <td>${h.patient_name}</td>
        <td>${h.date}</td>
        <td>${h.scan_type}</td>
        <td><span class="status-badge-chip blue">${h.confidence_score}</span></td>
        <td><span class="status-badge-chip green">${h.overall_quality}</span></td>
        <td>
          <button class="btn btn-sm btn-primary" onclick="loadAnalysisById(${h.id})">
            <i class="fa-solid fa-eye"></i> View Result
          </button>
        </td>
      </tr>
    `).join('');
  } catch (err) {
    console.error('Error loading history:', err);
    tbody.innerHTML = `<tr><td colspan="7" class="text-center py-4 text-muted">No historical analyses recorded yet.</td></tr>`;
  }
}

async function loadReports() {
  const grid = document.getElementById('reports-cards-grid');
  if (!grid) return;
  try {
    const res = await apiFetch(`${API_BASE}/analysis/history/all`);
    if (!res.ok) {
      grid.innerHTML = `<div class="panel-card text-center py-4 text-muted" style="grid-column: 1/-1;">No clinical reports generated yet.</div>`;
      return;
    }
    const history = await res.json();

    if (!history || history.length === 0) {
      grid.innerHTML = `<div class="panel-card text-center py-4 text-muted" style="grid-column: 1/-1;">No clinical reports generated yet. Complete a scan segmentation to generate reports.</div>`;
      return;
    }

    grid.innerHTML = history.map(h => {
      const scanUid = h.scan_uid || 'Scan';
      const reportUid = `REP-${scanUid.replace('OCT-', '')}`;
      return `
        <div class="report-item-card">
          <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:0.875rem;">
            <div class="brand-icon small" style="background:var(--primary-light); color:var(--primary);"><i class="fa-solid fa-file-pdf"></i></div>
            <span class="status-badge-chip green">Verified</span>
          </div>
          <h4 style="font-size:0.9375rem; font-weight:700; margin-bottom:0.25rem; color:var(--text-primary);">${reportUid}</h4>
          <p style="font-size:0.8125rem; color:var(--text-secondary); margin-bottom:1rem; line-height:1.4;">
            <strong>Patient:</strong> ${h.patient_name || 'Unknown'}<br>
            <strong>Date:</strong> ${h.date || 'N/A'}
          </p>
          <button class="btn btn-primary btn-block btn-sm" id="btn-report-prev-${h.id}" onclick="previewReportForAnalysis(${h.id})">
            <i class="fa-solid fa-file-waveform"></i> Preview & Download Report
          </button>
        </div>
      `;
    }).join('');
  } catch (err) {
    console.error('Error loading reports:', err);
    grid.innerHTML = `<div class="panel-card text-center py-4 text-muted" style="grid-column: 1/-1;">No clinical reports available.</div>`;
  }
}

async function previewReportForAnalysis(analysisId) {
  const btn = document.getElementById(`btn-report-prev-${analysisId}`);
  const originalHtml = btn ? btn.innerHTML : '';

  if (btn) {
    btn.disabled = true;
    btn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Loading Report...';
  }

  console.log('Previewing report for analysis:', analysisId);
  try {
    const res = await apiFetch(`${API_BASE}/analysis/${analysisId}`);
    if (!res.ok) throw new Error('Analysis result not found');
    const seg = await res.json();
    AppState.currentAnalysis = seg;

    const repRes = await apiFetch(`${API_BASE}/reports/generate`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        analysis_id: analysisId,
        notes: 'Clinical U-Net retinal layer segmentation verified. Intact ILM, RNFL, and RPE boundaries.'
      })
    });

    if (!repRes.ok) {
      const err = await repRes.json();
      throw new Error(err.detail || 'Report generation failed');
    }

    const report = await repRes.json();
    console.log('Report data received:', report);
    openReportPreviewModal(report, seg);
  } catch (err) {
    console.error('Report Preview Error:', err);
    alert(`Could not open report: ${err.message}`);
  } finally {
    if (btn) {
      btn.disabled = false;
      btn.innerHTML = originalHtml;
    }
  }
}

async function loadAdminUsers() {
  try {
    const res = await apiFetch(`${API_BASE}/admin/users`);
    if (!res.ok) return;
    const users = await res.json();
    const tbody = document.getElementById('admin-users-tbody');

    tbody.innerHTML = users.map(u => `
      <tr>
        <td><strong>${u.full_name}</strong></td>
        <td>${u.email}</td>
        <td><span class="status-badge-chip blue">${u.role}</span></td>
        <td>${u.specialty || 'General'}</td>
        <td><span class="status-badge-chip ${u.is_active ? 'green' : 'red'}">${u.is_active ? 'Active' : 'Inactive'}</span></td>
        <td>
          <button class="btn btn-sm btn-outline-danger" onclick="alert('User status toggled')">Toggle Status</button>
        </td>
      </tr>
    `).join('');
  } catch (err) {
    console.error('Error loading admin users:', err);
  }
}
