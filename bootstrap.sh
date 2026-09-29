#!/bin/bash
set -e
echo "Creating Rashid Abbas CC project files under ./RashidAbbasCC ..."
mkdir -p "$(dirname 'RashidAbbasCC/README.md')"
cat > 'RashidAbbasCC/README.md' << 'RACC_EOF'
# RASHID ABBAS CC — Phase 1 (core + security)

Included: cricket math engine (overs-as-balls, batting/bowling totals, validation), Firestore rules.
NOT yet included: Gradle setup, Compose UI, navigation, Auth/Firestore repositories, charts, export.

## Firebase setup (needed for later phases)
1. console.firebase.google.com → create project → add Android app (package `com.rashidabbascc`).
2. Add SHA-1 and SHA-256: `./gradlew signingReport` (Android Studio terminal).
3. Download `google-services.json` → put in `app/` (never commit it publicly).
4. Authentication → enable Email/Password, Google, Facebook.
5. Facebook: developers.facebook.com → create app → copy App ID + Client Token into
   `res/values/secrets.xml` (git-ignored) → paste App ID & App Secret in Firebase's Facebook provider,
   and add Firebase's OAuth redirect URI in Facebook Login settings.
6. Firestore → create database → Rules tab → paste `firestore.rules` → Publish.
7. First admin: sign up, then in Firestore set `users/{your uid}.role = "admin"` manually.

## Design decision for you
Team stats/leaderboards: count only VERIFIED/LOCKED records (`countable()`), or include PENDING too?

## Phase 2 — what's now included
- Full Gradle project (Kotlin + Compose + Material 3 + Firebase BoM + Google Sign-In + Facebook Login).
- Screens: Login, Sign Up (with Jersey Number + Playing Role), placeholder Home/Dashboard.
- `AuthRepository`: email sign-up/login, Google, Facebook, forgot password, logout, delete account.
  Creates a `players/{uid}` profile doc + `users/{uid}` role doc on first sign-in — passwords are
  never stored in Firestore (Firebase Auth handles them).
- Friendly error messages for wrong password, duplicate email, no network, etc.
- Offline-first Firestore cache enabled in `RashidAbbasApp.kt`.

## Build it in GitHub Codespaces (from your phone browser, Desktop-site mode)
1. On github.com, create a new **empty** repository, e.g. `RashidAbbasCC`.
2. Open it → **Code** → **Codespaces** tab → **Create codespace on main**.
3. In the file explorer (left sidebar), use the "..." menu → **Upload...** and upload this zip file.
4. In the terminal at the bottom, run:
   ```
   unzip RashidAbbasCC-phase2.zip -d .
   rm RashidAbbasCC-phase2.zip
   ```
5. Gradle wrapper isn't included (binary files aren't safely hand-written). Install Gradle once and generate it:
   ```
   sudo apt-get update && sudo apt-get install -y gradle
   gradle wrapper --gradle-version 8.7
   ```
6. **Before building**, do the Firebase & Facebook setup below — the app won't compile Google/Facebook
   login correctly without real IDs in `app/src/main/res/values/strings.xml` and `google-services.json`.
7. Build the APK:
   ```
   ./gradlew assembleDebug
   ```
8. Find it at `app/build/outputs/apk/debug/app-debug.apk` → right-click → **Download** → install on your phone
   (you'll need to allow "install from unknown sources" once).

## Firebase & OAuth setup (required before the APK will actually log in)
1. console.firebase.google.com → create project → **Add app → Android** → package name `com.rashidabbascc`.
2. Get SHA-1/SHA-256: in Codespaces terminal, `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android` (Android Studio's default debug keystore; Codespaces may need `keytool -genkey` first time — ask me if it's missing).
3. Download `google-services.json` from Firebase → upload it into the `app/` folder in Codespaces.
4. Firebase Console → Authentication → Sign-in method → enable **Email/Password** and **Google**.
   Copy the **Web client ID** shown under Google → paste into `strings.xml` → `default_web_client_id`.
5. developers.facebook.com → create app → Facebook Login product → copy **App ID** and **Client Token**
   → paste into `strings.xml` (`facebook_app_id`, `fb_login_protocol_scheme` becomes `fb<APP_ID>`, `facebook_client_token`).
   In Firebase → Authentication → Sign-in method → Facebook, paste the App ID + App Secret, then copy
   Firebase's OAuth redirect URI into Facebook's Login settings → Valid OAuth Redirect URIs.
6. Firestore Database → create (production mode) → Rules tab → paste `firestore.rules` from this repo → Publish.
7. First admin: sign up once in the app, then in Firestore manually set `users/{that uid}.role` to `"admin"`.

## Known placeholders / next phase
- Home screen is a placeholder ("You're logged in!") — Phase 3 builds the real dashboard,
  + ADD MY MATCH, batting/bowling/fielding forms, My Matches, Team Stats, Leaderboards, charts.
- Admin panel, seasons, awards, and PDF/CSV export are Phase 4.

RACC_EOF
mkdir -p "$(dirname 'RashidAbbasCC/app/build.gradle.kts')"
cat > 'RashidAbbasCC/app/build.gradle.kts' << 'RACC_EOF'
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.rashidabbascc"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.rashidabbascc"
        minSdk = 24
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }

    buildFeatures {
        compose = true
        buildConfig = true
    }

    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
}

dependencies {
    // Compose
    implementation(platform("androidx.compose:compose-bom:2024.09.00"))
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-graphics")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.material:material-icons-extended")
    implementation("androidx.activity:activity-compose:1.9.2")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.8.6")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.8.6")
    implementation("androidx.navigation:navigation-compose:2.8.0")
    implementation("androidx.core:core-ktx:1.13.1")

    // Firebase (BoM manages versions)
    implementation(platform("com.google.firebase:firebase-bom:33.3.0"))
    implementation("com.google.firebase:firebase-auth-ktx")
    implementation("com.google.firebase:firebase-firestore-ktx")
    implementation("com.google.firebase:firebase-storage-ktx")

    // Google Sign-In
    implementation("com.google.android.gms:play-services-auth:21.2.0")

    // Facebook Login
    implementation("com.facebook.android:facebook-login:17.0.0")

    // Coroutines
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-play-services:1.8.1")

    // Coil (profile photos)
    implementation("io.coil-kt:coil-compose:2.6.0")

    debugImplementation("androidx.compose.ui:ui-tooling")
}

RACC_EOF
mkdir -p "$(dirname 'RashidAbbasCC/app/proguard-rules.pro')"
cat > 'RashidAbbasCC/app/proguard-rules.pro' << 'RACC_EOF'
# Add project specific ProGuard rules here.

RACC_EOF
mkdir -p "$(dirname 'RashidAbbasCC/app/src/main/AndroidManifest.xml')"
cat > 'RashidAbbasCC/app/src/main/AndroidManifest.xml' << 'RACC_EOF'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

    <application
        android:name=".RashidAbbasApp"
        android:allowBackup="true"
        android:icon="@mipmap/ic_launcher"
        android:label="@string/app_name"
        android:supportsRtl="true"
        android:theme="@style/Theme.RashidAbbasCC">

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:theme="@style/Theme.RashidAbbasCC">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>

        <!-- Facebook Login -->
        <meta-data
            android:name="com.facebook.sdk.ApplicationId"
            android:value="@string/facebook_app_id" />
        <meta-data
            android:name="com.facebook.sdk.ClientToken"
            android:value="@string/facebook_client_token" />
        <activity
            android:name="com.facebook.FacebookActivity"
            android:configChanges="keyboard|keyboardHidden|screenLayout|screenSize|orientation"
            android:label="@string/app_name"
            android:exported="false" />
        <activity
            android:name="com.facebook.CustomTabActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data android:scheme="@string/fb_login_protocol_scheme" />
            </intent-filter>
        </activity>
    </application>
</manifest>

RACC_EOF
mkdir -p "$(dirname 'RashidAbbasCC/app/src/main/java/com/rashidabbascc/MainActivity.kt')"
cat > 'RashidAbbasCC/app/src/main/java/com/rashidabbascc/MainActivity.kt' << 'RACC_EOF'
package com.rashidabbascc

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.activity.viewModels
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import androidx.lifecycle.viewmodel.compose.viewModel
import com.facebook.CallbackManager
import com.facebook.FacebookCallback
import com.facebook.FacebookException
import com.facebook.login.LoginManager
import com.facebook.login.LoginResult
import com.google.android.gms.auth.api.signin.GoogleSignIn
import com.google.android.gms.auth.api.signin.GoogleSignInClient
import com.google.android.gms.auth.api.signin.GoogleSignInOptions
import com.google.android.gms.common.api.ApiException
import com.rashidabbascc.ui.auth.AuthViewModel
import com.rashidabbascc.ui.nav.AppNavGraph
import com.rashidabbascc.ui.theme.RashidAbbasCCTheme

/**
 * Google and Facebook sign-in need an Activity (to launch the account picker / browser),
 * so those launchers live here and the AuthViewModel is shared with the nav graph.
 */
class MainActivity : ComponentActivity() {

    private lateinit var googleClient: GoogleSignInClient
    private val fbCallbackManager = CallbackManager.Factory.create()
    val authViewModel: AuthViewModel by viewModels()

    private val googleLauncher = registerForActivityResult(ActivityResultContracts.StartActivityForResult()) { result ->
        val task = GoogleSignIn.getSignedInAccountFromIntent(result.data)
        try {
            val account = task.getResult(ApiException::class.java)
            authViewModel.onGoogleSignIn(account)
        } catch (e: ApiException) {
            authViewModel.onGoogleSignIn(null)
        }
    }

    fun launchGoogleSignIn() {
        googleLauncher.launch(googleClient.signInIntent)
    }

    fun launchFacebookLogin() {
        LoginManager.getInstance().logInWithReadPermissions(this, listOf("email", "public_profile"))
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val gso = GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
            .requestIdToken(getString(R.string.default_web_client_id))
            .requestEmail()
            .build()
        googleClient = GoogleSignIn.getClient(this, gso)

        LoginManager.getInstance().registerCallback(fbCallbackManager, object : FacebookCallback<LoginResult> {
            override fun onSuccess(result: LoginResult) = authViewModel.onFacebookSignIn(result.accessToken)
            override fun onCancel() = authViewModel.onFacebookSignIn(null)
            override fun onError(error: FacebookException) = authViewModel.onFacebookSignIn(null)
        })

        setContent {
            RashidAbbasCCTheme {
                Surface(modifier = Modifier.fillMaxSize()) {
                    AppNavGraph(activity = this)
                }
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: android.content.Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        fbCallbackManager.onActivityResult(requestCode, resultCode, data)
    }
}

RACC_EOF
mkdir -p "$(dirname 'RashidAbbasCC/app/src/main/java/com/rashidabbascc/RashidAbbasApp.kt')"
cat > 'RashidAbbasCC/app/src/main/java/com/rashidabbascc/RashidAbbasApp.kt' << 'RACC_EOF'
package com.rashidabbascc

import android.app.Application
import com.google.firebase.FirebaseApp
import com.google.firebase.firestore.FirebaseFirestoreSettings
import com.google.firebase.firestore.firestore
import com.google.firebase.ktx.Firebase

class RashidAbbasApp : Application() {
    override fun onCreate() {
        super.onCreate()
        FirebaseApp.initializeApp(this)
        // Offline-first: cache Firestore data locally, sync automatically when back online.
        Firebase.firestore.firestoreSettings = FirebaseFirestoreSettings.Builder()
            .setLocalCacheSettings(
                com.google.firebase.firestore.persistentCacheSettings {}
            )
            .build()
    }
}

RACC_EOF
mkdir -p "$(dirname 'RashidAbbasCC/app/src/main/java/com/rashidabbascc/core/CricketStats.kt')"
cat > 'RashidAbbasCC/app/src/main/java/com/rashidabbascc/core/CricketStats.kt' << 'RACC_EOF'
package com.rashidabbascc.core

/** Cricket overs are stored as legal balls. Never use decimal math for overs. */
object Overs {
    fun toBalls(overs: Int, extraBalls: Int): Int = overs * 6 + extraBalls
    fun display(legalBalls: Int): String = "${legalBalls / 6}.${legalBalls % 6}"
}

enum class Dismissal { NOT_OUT, BOWLED, CAUGHT, LBW, RUN_OUT, STUMPED, HIT_WICKET, RETIRED_HURT, RETIRED_OUT, OTHER }
enum class Verification { PENDING, VERIFIED, LOCKED }

data class Batting(
    val didBat: Boolean = false, val runs: Int = 0, val balls: Int = 0,
    val fours: Int = 0, val sixes: Int = 0, val dismissal: Dismissal = Dismissal.NOT_OUT
)

data class Bowling(
    val didBowl: Boolean = false, val legalBalls: Int = 0, val runsConceded: Int = 0,
    val wickets: Int = 0, val maidens: Int = 0, val wides: Int = 0, val noBalls: Int = 0,
    val byes: Int = 0, val legByes: Int = 0
)

data class Fielding(val catches: Int = 0, val runOuts: Int = 0, val stumpings: Int = 0)

data class Performance(
    val performanceId: String = "", val playerId: String = "", val seasonId: String = "",
    val matchId: String = "", val batting: Batting = Batting(), val bowling: Bowling = Bowling(),
    val fielding: Fielding = Fielding(), val status: Verification = Verification.PENDING
)

/** Returns a list of user-friendly errors; empty list = valid. */
fun validate(p: Performance): List<String> {
    val e = mutableListOf<String>()
    val b = p.batting; val w = p.bowling; val f = p.fielding
    if (b.didBat) {
        if (listOf(b.runs, b.balls, b.fours, b.sixes).any { it < 0 }) e += "Batting values cannot be negative."
        if (b.fours * 4 > b.runs) e += "Fours × 4 cannot exceed runs."
        if (b.sixes * 6 > b.runs) e += "Sixes × 6 cannot exceed runs."
        if (b.fours * 4 + b.sixes * 6 > b.runs) e += "Boundary runs cannot exceed total runs."
    }
    if (w.didBowl) {
        if (listOf(w.legalBalls, w.runsConceded, w.wickets, w.maidens, w.wides, w.noBalls, w.byes, w.legByes).any { it < 0 })
            e += "Bowling values cannot be negative."
        if (w.wickets > 10) e += "Wickets cannot exceed 10."
        if (w.maidens > w.legalBalls / 6) e += "Maidens cannot exceed completed overs."
    }
    if (listOf(f.catches, f.runOuts, f.stumpings).any { it < 0 }) e += "Fielding values cannot be negative."
    return e
}

/** Extra-ball input check for the "additional balls" field (0..5). */
fun validExtraBalls(x: Int) = x in 0..5

data class BattingTotals(
    val matches: Int, val innings: Int, val runs: Int, val balls: Int, val fours: Int, val sixes: Int,
    val notOuts: Int, val highScore: Int, val highScoreNotOut: Boolean,
    val thirties: Int, val fifties: Int, val hundreds: Int
) {
    val dismissals get() = innings - notOuts
    /** null => show "N/A" */
    val average: Double? get() = if (dismissals > 0) runs.toDouble() / dismissals else null
    val strikeRate: Double? get() = if (balls > 0) runs * 100.0 / balls else null
}

data class BowlingTotals(
    val matches: Int, val legalBalls: Int, val runsConceded: Int, val wickets: Int, val maidens: Int,
    val wides: Int, val noBalls: Int, val bestWickets: Int, val bestRuns: Int,
    val w2: Int, val w3: Int, val w4: Int, val w5: Int, val w6plus: Int
) {
    val overs get() = Overs.display(legalBalls)
    val economy: Double? get() = if (legalBalls > 0) runsConceded * 6.0 / legalBalls else null
    val average: Double? get() = if (wickets > 0) runsConceded.toDouble() / wickets else null
    val strikeRate: Double? get() = if (wickets > 0) legalBalls.toDouble() / wickets else null
    val best: String get() = if (matches == 0) "N/A" else "$bestWickets/$bestRuns"
}

fun battingTotals(list: List<Performance>): BattingTotals {
    val inns = list.filter { it.batting.didBat }
    val notOut = inns.count { it.batting.dismissal == Dismissal.NOT_OUT || it.batting.dismissal == Dismissal.RETIRED_HURT }
    val hs = inns.maxWithOrNull(compareBy({ it.batting.runs }, { it.batting.dismissal == Dismissal.NOT_OUT }))
    return BattingTotals(
        matches = list.size, innings = inns.size,
        runs = inns.sumOf { it.batting.runs }, balls = inns.sumOf { it.batting.balls },
        fours = inns.sumOf { it.batting.fours }, sixes = inns.sumOf { it.batting.sixes },
        notOuts = notOut, highScore = hs?.batting?.runs ?: 0,
        highScoreNotOut = hs?.batting?.dismissal == Dismissal.NOT_OUT,
        thirties = inns.count { it.batting.runs in 30..49 },
        fifties = inns.count { it.batting.runs in 50..99 },
        hundreds = inns.count { it.batting.runs >= 100 }
    )
}

fun bowlingTotals(list: List<Performance>): BowlingTotals {
    val spells = list.filter { it.bowling.didBowl }
    // Best bowling: most wickets, then fewest runs.
    val best = spells.minWithOrNull(compareBy({ -it.bowling.wickets }, { it.bowling.runsConceded }))
    return BowlingTotals(
        matches = spells.size, legalBalls = spells.sumOf { it.bowling.legalBalls },
        runsConceded = spells.sumOf { it.bowling.runsConceded }, wickets = spells.sumOf { it.bowling.wickets },
        maidens = spells.sumOf { it.bowling.maidens }, wides = spells.sumOf { it.bowling.wides },
        noBalls = spells.sumOf { it.bowling.noBalls },
        bestWickets = best?.bowling?.wickets ?: 0, bestRuns = best?.bowling?.runsConceded ?: 0,
        w2 = spells.count { it.bowling.wickets == 2 }, w3 = spells.count { it.bowling.wickets == 3 },
        w4 = spells.count { it.bowling.wickets == 4 }, w5 = spells.count { it.bowling.wickets == 5 },
        w6plus = spells.count { it.bowling.wickets >= 6 }
    )
}

fun fmt(v: Double?, digits: Int = 2): String =
    if (v == null || v.isNaN() || v.isInfinite()) "N/A" else "%.${digits}f".format(v)

/** Team/leaderboard stats should count only VERIFIED or LOCKED records (see README). */
fun countable(list: List<Performance>) = list.filter { it.status != Verification.PENDING }

RACC_EOF
mkdir -p "$(dirname 'RashidAbbasCC/app/src/main/java/com/rashidabbascc/data/AuthRepository.kt')"
cat > 'RashidAbbasCC/app/src/main/java/com/rashidabbascc/data/AuthRepository.kt' << 'RACC_EOF'
package com.rashidabbascc.data

import com.facebook.AccessToken
import com.google.android.gms.auth.api.signin.GoogleSignInAccount
import com.google.firebase.auth.FacebookAuthProvider
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.GoogleAuthProvider
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.SetOptions
import kotlinx.coroutines.tasks.await

enum class PlayingRole { BATSMAN, BOWLER, ALL_ROUNDER, WICKETKEEPER }

data class PlayerProfile(
    val playerId: String = "",
    val fullName: String = "",
    val email: String = "",
    val jerseyNumber: Int = 0,
    val playingRole: String = PlayingRole.BATSMAN.name,
    val battingStyle: String = "",
    val bowlingStyle: String = "",
    val photoUrl: String = "",
    val role: String = "player", // "player" or "admin"
    val active: Boolean = true,
    val joinDate: Long = System.currentTimeMillis()
)

/** Friendly text for common Firebase auth failures. */
fun friendlyAuthError(t: Throwable): String {
    val msg = t.message ?: ""
    return when {
        "email address is already in use" in msg -> "This email is already registered. Try logging in instead."
        "password is invalid" in msg || "no user record" in msg -> "Wrong email or password."
        "badly formatted" in msg -> "Please enter a valid email address."
        "network error" in msg.lowercase() -> "No internet connection. Please check your network and try again."
        "weak password" in msg.lowercase() -> "Password should be at least 6 characters."
        else -> "Something went wrong. Please try again."
    }
}

class AuthRepository(
    private val auth: FirebaseAuth = FirebaseAuth.getInstance(),
    private val db: FirebaseFirestore = FirebaseFirestore.getInstance()
) {
    val currentUserId: String? get() = auth.currentUser?.uid

    suspend fun signUpWithEmail(
        fullName: String, email: String, password: String,
        jerseyNumber: Int, role: PlayingRole
    ): Result<Unit> = runCatching {
        val result = auth.createUserWithEmailAndPassword(email, password).await()
        val uid = result.user?.uid ?: error("Sign up failed. Please try again.")
        val profile = PlayerProfile(
            playerId = uid, fullName = fullName, email = email,
            jerseyNumber = jerseyNumber, playingRole = role.name
        )
        db.collection("players").document(uid).set(profile).await()
        db.collection("users").document(uid)
            .set(mapOf("role" to "player", "email" to email), SetOptions.merge()).await()
    }

    suspend fun loginWithEmail(email: String, password: String): Result<Unit> = runCatching {
        auth.signInWithEmailAndPassword(email, password).await()
        Unit
    }

    suspend fun sendPasswordReset(email: String): Result<Unit> = runCatching {
        auth.sendPasswordResetEmail(email).await()
    }

    suspend fun signInWithGoogle(account: GoogleSignInAccount): Result<Unit> = runCatching {
        val credential = GoogleAuthProvider.getCredential(account.idToken, null)
        val result = auth.signInWithCredential(credential).await()
        ensurePlayerDoc(result.user?.uid, result.user?.displayName, result.user?.email)
    }

    suspend fun signInWithFacebook(token: AccessToken): Result<Unit> = runCatching {
        val credential = FacebookAuthProvider.getCredential(token.token)
        val result = auth.signInWithCredential(credential).await()
        ensurePlayerDoc(result.user?.uid, result.user?.displayName, result.user?.email)
    }

    private suspend fun ensurePlayerDoc(uid: String?, name: String?, email: String?) {
        if (uid == null) return
        val doc = db.collection("players").document(uid).get().await()
        if (!doc.exists()) {
            db.collection("players").document(uid)
                .set(PlayerProfile(playerId = uid, fullName = name ?: "", email = email ?: "")).await()
            db.collection("users").document(uid)
                .set(mapOf("role" to "player", "email" to (email ?: "")), SetOptions.merge()).await()
        }
    }

    fun logout() = auth.signOut()

    suspend fun deleteAccount(): Result<Unit> = runCatching {
        auth.currentUser?.delete()?.await()
        Unit
    }
}

RACC_EOF
mkdir -p "$(dirname 'RashidAbbasCC/app/src/main/java/com/rashidabbascc/ui/auth/AuthViewModel.kt')"
cat > 'RashidAbbasCC/app/src/main/java/com/rashidabbascc/ui/auth/AuthViewModel.kt' << 'RACC_EOF'
package com.rashidabbascc.ui.auth

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.rashidabbascc.data.AuthRepository
import com.rashidabbascc.data.PlayingRole
import com.rashidabbascc.data.friendlyAuthError
import com.google.android.gms.auth.api.signin.GoogleSignInAccount
import com.facebook.AccessToken
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

sealed class AuthUiState {
    data object Idle : AuthUiState()
    data object Loading : AuthUiState()
    data object Success : AuthUiState()
    data class Error(val message: String) : AuthUiState()
}

class AuthViewModel(private val repo: AuthRepository = AuthRepository()) : ViewModel() {

    private val _state = MutableStateFlow<AuthUiState>(AuthUiState.Idle)
    val state: StateFlow<AuthUiState> = _state.asStateFlow()

    val isLoggedIn: Boolean get() = repo.currentUserId != null

    fun login(email: String, password: String) {
        if (email.isBlank() || password.isBlank()) {
            _state.value = AuthUiState.Error("Please enter your email and password.")
            return
        }
        _state.value = AuthUiState.Loading
        viewModelScope.launch {
            repo.loginWithEmail(email.trim(), password)
                .onSuccess { _state.value = AuthUiState.Success }
                .onFailure { _state.value = AuthUiState.Error(friendlyAuthError(it)) }
        }
    }

    fun signUp(
        fullName: String, email: String, password: String, confirmPassword: String,
        jerseyNumber: String, role: PlayingRole
    ) {
        if (fullName.isBlank() || email.isBlank() || password.isBlank()) {
            _state.value = AuthUiState.Error("Please fill in all required fields.")
            return
        }
        if (password != confirmPassword) {
            _state.value = AuthUiState.Error("Passwords do not match.")
            return
        }
        if (password.length < 6) {
            _state.value = AuthUiState.Error("Password should be at least 6 characters.")
            return
        }
        val jersey = jerseyNumber.toIntOrNull() ?: 0
        _state.value = AuthUiState.Loading
        viewModelScope.launch {
            repo.signUpWithEmail(fullName.trim(), email.trim(), password, jersey, role)
                .onSuccess { _state.value = AuthUiState.Success }
                .onFailure { _state.value = AuthUiState.Error(friendlyAuthError(it)) }
        }
    }

    fun forgotPassword(email: String) {
        if (email.isBlank()) {
            _state.value = AuthUiState.Error("Enter your email first, then tap 'Forgot Password'.")
            return
        }
        viewModelScope.launch {
            repo.sendPasswordReset(email.trim())
                .onSuccess { _state.value = AuthUiState.Error("Password reset email sent. Check your inbox.") }
                .onFailure { _state.value = AuthUiState.Error(friendlyAuthError(it)) }
        }
    }

    fun onGoogleSignIn(account: GoogleSignInAccount?) {
        if (account == null) {
            _state.value = AuthUiState.Error("Google sign-in was cancelled.")
            return
        }
        _state.value = AuthUiState.Loading
        viewModelScope.launch {
            repo.signInWithGoogle(account)
                .onSuccess { _state.value = AuthUiState.Success }
                .onFailure { _state.value = AuthUiState.Error(friendlyAuthError(it)) }
        }
    }

    fun onFacebookSignIn(token: AccessToken?) {
        if (token == null) {
            _state.value = AuthUiState.Error("Facebook login was cancelled.")
            return
        }
        _state.value = AuthUiState.Loading
        viewModelScope.launch {
            repo.signInWithFacebook(token)
                .onSuccess { _state.value = AuthUiState.Success }
                .onFailure { _state.value = AuthUiState.Error(friendlyAuthError(it)) }
        }
    }

    fun resetState() { _state.value = AuthUiState.Idle }
}

RACC_EOF
mkdir -p "$(dirname 'RashidAbbasCC/app/src/main/java/com/rashidabbascc/ui/auth/LoginScreen.kt')"
cat > 'RashidAbbasCC/app/src/main/java/com/rashidabbascc/ui/auth/LoginScreen.kt' << 'RACC_EOF'
package com.rashidabbascc.ui.auth

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Sports
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material.icons.filled.VisibilityOff
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun LoginScreen(
    vm: AuthViewModel = viewModel(),
    onLoggedIn: () -> Unit,
    onGoToSignUp: () -> Unit,
    onGoogleClick: () -> Unit,
    onFacebookClick: () -> Unit
) {
    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var showPassword by remember { mutableStateOf(false) }
    val state by vm.state.collectAsState()

    LaunchedEffect(state) {
        if (state is AuthUiState.Success) onLoggedIn()
    }

    Scaffold { padding ->
        Column(
            modifier = Modifier
                .padding(padding)
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 24.dp, vertical = 32.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Icon(Icons.Filled.Sports, contentDescription = null, tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(64.dp))
            Spacer(Modifier.height(8.dp))
            Text("RASHID ABBAS CC", style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Bold)
            Text("Club Statistics", style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant)
            Spacer(Modifier.height(32.dp))

            OutlinedButton(onClick = onGoogleClick, modifier = Modifier.fillMaxWidth()) {
                Text("Continue with Google")
            }
            Spacer(Modifier.height(10.dp))
            OutlinedButton(onClick = onFacebookClick, modifier = Modifier.fillMaxWidth()) {
                Text("Continue with Facebook")
            }

            Spacer(Modifier.height(20.dp))
            Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.fillMaxWidth()) {
                HorizontalDivider(Modifier.weight(1f))
                Text("  or  ", style = MaterialTheme.typography.bodySmall)
                HorizontalDivider(Modifier.weight(1f))
            }
            Spacer(Modifier.height(20.dp))

            OutlinedTextField(
                value = email, onValueChange = { email = it },
                label = { Text("Email") }, singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Email),
                modifier = Modifier.fillMaxWidth()
            )
            Spacer(Modifier.height(12.dp))
            OutlinedTextField(
                value = password, onValueChange = { password = it },
                label = { Text("Password") }, singleLine = true,
                visualTransformation = if (showPassword) VisualTransformation.None else PasswordVisualTransformation(),
                trailingIcon = {
                    IconButton(onClick = { showPassword = !showPassword }) {
                        Icon(if (showPassword) Icons.Filled.VisibilityOff else Icons.Filled.Visibility, null)
                    }
                },
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password),
                modifier = Modifier.fillMaxWidth()
            )
            Spacer(Modifier.height(4.dp))
            TextButton(onClick = { vm.forgotPassword(email) }, modifier = Modifier.align(Alignment.End)) {
                Text("Forgot Password?")
            }

            if (state is AuthUiState.Error) {
                Text(
                    (state as AuthUiState.Error).message,
                    color = MaterialTheme.colorScheme.error,
                    style = MaterialTheme.typography.bodySmall,
                    modifier = Modifier.padding(vertical = 4.dp)
                )
            }

            Spacer(Modifier.height(8.dp))
            Button(
                onClick = { vm.login(email, password) },
                enabled = state !is AuthUiState.Loading,
                modifier = Modifier.fillMaxWidth().height(48.dp)
            ) {
                if (state is AuthUiState.Loading) {
                    CircularProgressIndicator(modifier = Modifier.size(20.dp), strokeWidth = 2.dp)
                } else {
                    Text("Login")
                }
            }

            Spacer(Modifier.height(16.dp))
            TextButton(onClick = onGoToSignUp) { Text("Don't have an account? Create Account") }
        }
    }
}

RACC_EOF
mkdir -p "$(dirname 'RashidAbbasCC/app/src/main/java/com/rashidabbascc/ui/auth/SignUpScreen.kt')"
cat > 'RashidAbbasCC/app/src/main/java/com/rashidabbascc/ui/auth/SignUpScreen.kt' << 'RACC_EOF'
package com.rashidabbascc.ui.auth

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.rashidabbascc.data.PlayingRole

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SignUpScreen(
    vm: AuthViewModel = viewModel(),
    onSignedUp: () -> Unit,
    onGoToLogin: () -> Unit
) {
    var fullName by remember { mutableStateOf("") }
    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var confirmPassword by remember { mutableStateOf("") }
    var jersey by remember { mutableStateOf("") }
    var role by remember { mutableStateOf(PlayingRole.BATSMAN) }
    var roleMenuOpen by remember { mutableStateOf(false) }
    val state by vm.state.collectAsState()

    LaunchedEffect(state) {
        if (state is AuthUiState.Success) onSignedUp()
    }

    Scaffold(topBar = { TopAppBar(title = { Text("Create Account") }) }) { padding ->
        Column(
            modifier = Modifier
                .padding(padding)
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 24.dp, vertical = 16.dp)
        ) {
            Text("Join Rashid Abbas CC", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
            Spacer(Modifier.height(16.dp))

            OutlinedTextField(fullName, { fullName = it }, label = { Text("Full Name") },
                singleLine = true, modifier = Modifier.fillMaxWidth())
            Spacer(Modifier.height(10.dp))
            OutlinedTextField(email, { email = it }, label = { Text("Email") }, singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Email),
                modifier = Modifier.fillMaxWidth())
            Spacer(Modifier.height(10.dp))
            OutlinedTextField(password, { password = it }, label = { Text("Password") }, singleLine = true,
                visualTransformation = PasswordVisualTransformation(),
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password),
                modifier = Modifier.fillMaxWidth())
            Spacer(Modifier.height(10.dp))
            OutlinedTextField(confirmPassword, { confirmPassword = it }, label = { Text("Confirm Password") },
                singleLine = true, visualTransformation = PasswordVisualTransformation(),
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password),
                modifier = Modifier.fillMaxWidth())
            Spacer(Modifier.height(10.dp))
            OutlinedTextField(jersey, { jersey = it.filter { c -> c.isDigit() } }, label = { Text("Jersey Number") },
                singleLine = true, keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                modifier = Modifier.fillMaxWidth())
            Spacer(Modifier.height(10.dp))

            ExposedDropdownMenuBox(expanded = roleMenuOpen, onExpandedChange = { roleMenuOpen = it }) {
                OutlinedTextField(
                    value = role.name.replace("_", "-").lowercase().replaceFirstChar { it.uppercase() },
                    onValueChange = {}, readOnly = true, label = { Text("Playing Role") },
                    trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = roleMenuOpen) },
                    modifier = Modifier.menuAnchor().fillMaxWidth()
                )
                ExposedDropdownMenu(expanded = roleMenuOpen, onDismissRequest = { roleMenuOpen = false }) {
                    PlayingRole.values().forEach { r ->
                        DropdownMenuItem(
                            text = { Text(r.name.replace("_", "-").lowercase().replaceFirstChar { it.uppercase() }) },
                            onClick = { role = r; roleMenuOpen = false }
                        )
                    }
                }
            }

            if (state is AuthUiState.Error) {
                Spacer(Modifier.height(8.dp))
                Text((state as AuthUiState.Error).message, color = MaterialTheme.colorScheme.error,
                    style = MaterialTheme.typography.bodySmall)
            }

            Spacer(Modifier.height(20.dp))
            Button(
                onClick = { vm.signUp(fullName, email, password, confirmPassword, jersey, role) },
                enabled = state !is AuthUiState.Loading,
                modifier = Modifier.fillMaxWidth().height(48.dp)
            ) {
                if (state is AuthUiState.Loading) {
                    CircularProgressIndicator(modifier = Modifier.size(20.dp), strokeWidth = 2.dp)
                } else Text("Create Account")
            }
            Spacer(Modifier.height(12.dp))
            TextButton(onClick = onGoToLogin, modifier = Modifier.align(Alignment.CenterHorizontally)) {
                Text("Already have an account? Login")
            }
        }
    }
}

RACC_EOF
mkdir -p "$(dirname 'RashidAbbasCC/app/src/main/java/com/rashidabbascc/ui/home/HomeScreen.kt')"
cat > 'RashidAbbasCC/app/src/main/java/com/rashidabbascc/ui/home/HomeScreen.kt' << 'RACC_EOF'
package com.rashidabbascc.ui.home

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp

/**
 * Placeholder dashboard — Phase 3 replaces this with live stats,
 * "+ ADD MY MATCH", and bottom navigation (Home / Matches / Stats / Leaderboard / Profile).
 */
@Composable
fun HomeScreen(onLogout: () -> Unit) {
    Scaffold(topBar = { TopAppBar(title = { Text("RASHID ABBAS CC") }) }) { padding ->
        Column(
            modifier = Modifier.padding(padding).fillMaxSize().padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Text("You're logged in!", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
            Spacer(Modifier.height(8.dp))
            Text("Dashboard, Add Match, and Stats screens arrive in Phase 3.",
                style = MaterialTheme.typography.bodyMedium, textAlign = androidx.compose.ui.text.style.TextAlign.Center)
            Spacer(Modifier.height(24.dp))
            OutlinedButton(onClick = onLogout) { Text("Logout") }
        }
    }
}

RACC_EOF
mkdir -p "$(dirname 'RashidAbbasCC/app/src/main/java/com/rashidabbascc/ui/nav/NavGraph.kt')"
cat > 'RashidAbbasCC/app/src/main/java/com/rashidabbascc/ui/nav/NavGraph.kt' << 'RACC_EOF'
package com.rashidabbascc.ui.nav

import androidx.compose.runtime.Composable
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.rashidabbascc.MainActivity
import com.rashidabbascc.ui.auth.LoginScreen
import com.rashidabbascc.ui.auth.SignUpScreen
import com.rashidabbascc.ui.home.HomeScreen
import com.google.firebase.auth.FirebaseAuth

object Routes {
    const val LOGIN = "login"
    const val SIGNUP = "signup"
    const val HOME = "home"
}

@Composable
fun AppNavGraph(
    activity: MainActivity,
    navController: NavHostController = rememberNavController()
) {
    val startDestination = if (FirebaseAuth.getInstance().currentUser != null) Routes.HOME else Routes.LOGIN

    NavHost(navController = navController, startDestination = startDestination) {
        composable(Routes.LOGIN) {
            LoginScreen(
                vm = activity.authViewModel,
                onLoggedIn = { navController.navigate(Routes.HOME) { popUpTo(Routes.LOGIN) { inclusive = true } } },
                onGoToSignUp = { navController.navigate(Routes.SIGNUP) },
                onGoogleClick = { activity.launchGoogleSignIn() },
                onFacebookClick = { activity.launchFacebookLogin() }
            )
        }
        composable(Routes.SIGNUP) {
            SignUpScreen(
                vm = activity.authViewModel,
                onSignedUp = { navController.navigate(Routes.HOME) { popUpTo(Routes.LOGIN) { inclusive = true } } },
                onGoToLogin = { navController.popBackStack() }
            )
        }
        composable(Routes.HOME) {
            HomeScreen(onLogout = {
                FirebaseAuth.getInstance().signOut()
                navController.navigate(Routes.LOGIN) { popUpTo(Routes.HOME) { inclusive = true } }
            })
        }
    }
}

RACC_EOF
mkdir -p "$(dirname 'RashidAbbasCC/app/src/main/java/com/rashidabbascc/ui/theme/Theme.kt')"
cat > 'RashidAbbasCC/app/src/main/java/com/rashidabbascc/ui/theme/Theme.kt' << 'RACC_EOF'
package com.rashidabbascc.ui.theme

import android.app.Activity
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

val ClubGreen = Color(0xFF0B4F30)
val ClubGold = Color(0xFFC9A227)
val ClubGoldLight = Color(0xFFE6C766)

private val LightColors = lightColorScheme(
    primary = ClubGreen, onPrimary = Color.White,
    secondary = ClubGold, onSecondary = Color.Black,
    background = Color(0xFFF7F8F6), surface = Color.White,
    error = Color(0xFFB3261E)
)

private val DarkColors = darkColorScheme(
    primary = ClubGoldLight, onPrimary = Color.Black,
    secondary = ClubGreen, onSecondary = Color.White,
    background = Color(0xFF10130F), surface = Color(0xFF181C16),
    error = Color(0xFFF2B8B5)
)

@Composable
fun RashidAbbasCCTheme(darkTheme: Boolean = isSystemInDarkTheme(), content: @Composable () -> Unit) {
    val colors = if (darkTheme) DarkColors else LightColors
    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as Activity).window
            window.statusBarColor = colors.primary.toArgb()
            WindowCompat.getInsetsController(window, view).isAppearanceLightStatusBars = !darkTheme
        }
    }
    MaterialTheme(colorScheme = colors, typography = Typography(), content = content)
}

RACC_EOF
mkdir -p "$(dirname 'RashidAbbasCC/app/src/main/res/drawable/ic_launcher_background.xml')"
cat > 'RashidAbbasCC/app/src/main/res/drawable/ic_launcher_background.xml' << 'RACC_EOF'
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp" android:height="108dp" android:viewportWidth="108" android:viewportHeight="108">
    <path android:fillColor="#0B4F30" android:pathData="M0,0h108v108h-108z" />
</vector>

RACC_EOF
mkdir -p "$(dirname 'RashidAbbasCC/app/src/main/res/drawable/ic_launcher_foreground.xml')"
cat > 'RashidAbbasCC/app/src/main/res/drawable/ic_launcher_foreground.xml' << 'RACC_EOF'
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp" android:height="108dp"
    android:viewportWidth="108" android:viewportHeight="108">
    <path android:fillColor="#FFFFFF" android:pathData="M54,20 L60,50 L54,88 L48,50 Z" />
    <path android:fillColor="#C9A227" android:pathData="M54,54 m-14,0 a14,14 0 1,0 28,0 a14,14 0 1,0 -28,0" />
</vector>

RACC_EOF
mkdir -p "$(dirname 'RashidAbbasCC/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml')"
cat > 'RashidAbbasCC/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml' << 'RACC_EOF'
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/ic_launcher_background" />
    <foreground android:drawable="@drawable/ic_launcher_foreground" />
</adaptive-icon>

RACC_EOF
mkdir -p "$(dirname 'RashidAbbasCC/app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml')"
cat > 'RashidAbbasCC/app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml' << 'RACC_EOF'
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/ic_launcher_background" />
    <foreground android:drawable="@drawable/ic_launcher_foreground" />
</adaptive-icon>

RACC_EOF
mkdir -p "$(dirname 'RashidAbbasCC/app/src/main/res/values/strings.xml')"
cat > 'RashidAbbasCC/app/src/main/res/values/strings.xml' << 'RACC_EOF'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">Rashid Abbas CC</string>

    <!-- ====== FILL THESE IN — see README "Firebase & OAuth setup" ====== -->
    <!-- From console.firebase.google.com -> Authentication -> Sign-in method -> Google -->
    <string name="default_web_client_id">REPLACE_WITH_FIREBASE_WEB_CLIENT_ID</string>

    <!-- From developers.facebook.com -> your app -> Settings -> Basic -->
    <string name="facebook_app_id">REPLACE_WITH_FACEBOOK_APP_ID</string>
    <string name="fb_login_protocol_scheme">fbREPLACE_WITH_FACEBOOK_APP_ID</string>
    <string name="facebook_client_token">REPLACE_WITH_FACEBOOK_CLIENT_TOKEN</string>
</resources>

RACC_EOF
mkdir -p "$(dirname 'RashidAbbasCC/app/src/main/res/values/themes.xml')"
cat > 'RashidAbbasCC/app/src/main/res/values/themes.xml' << 'RACC_EOF'
<?xml version="1.0" encoding="utf-8"?>
<resources xmlns:tools="http://schemas.android.com/tools">
    <style name="Theme.RashidAbbasCC" parent="android:Theme.Material.Light.NoActionBar" />
</resources>

RACC_EOF
mkdir -p "$(dirname 'RashidAbbasCC/app/src/main/res/values-night/themes.xml')"
cat > 'RashidAbbasCC/app/src/main/res/values-night/themes.xml' << 'RACC_EOF'
<?xml version="1.0" encoding="utf-8"?>
<resources xmlns:tools="http://schemas.android.com/tools">
    <style name="Theme.RashidAbbasCC" parent="android:Theme.Material.Light.NoActionBar" />
</resources>

RACC_EOF
mkdir -p "$(dirname 'RashidAbbasCC/app/src/main/res/xml/backup_rules.xml')"
cat > 'RashidAbbasCC/app/src/main/res/xml/backup_rules.xml' << 'RACC_EOF'
<?xml version="1.0" encoding="utf-8"?>
<full-backup-content />

RACC_EOF
mkdir -p "$(dirname 'RashidAbbasCC/build.gradle.kts')"
cat > 'RashidAbbasCC/build.gradle.kts' << 'RACC_EOF'
plugins {
    id("com.android.application") version "8.5.2" apply false
    id("org.jetbrains.kotlin.android") version "1.9.24" apply false
    id("com.google.gms.google-services") version "4.4.2" apply false
    id("org.jetbrains.kotlin.plugin.compose") version "1.9.24" apply false
}

RACC_EOF
mkdir -p "$(dirname 'RashidAbbasCC/firestore.rules')"
cat > 'RashidAbbasCC/firestore.rules' << 'RACC_EOF'
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function signedIn() { return request.auth != null; }
    function isAdmin() {
      return signedIn() && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }

    // users: role can only be set to 'player' by the user; only admin changes roles
    match /users/{uid} {
      allow read: if signedIn() && (request.auth.uid == uid || isAdmin());
      allow create: if signedIn() && request.auth.uid == uid && request.resource.data.role == 'player';
      allow update: if isAdmin() ||
        (request.auth.uid == uid && request.resource.data.role == resource.data.role);
      allow delete: if isAdmin() || request.auth.uid == uid;
    }

    // players: readable by all members (team stats); editable only by owner/admin
    match /players/{pid} {
      allow read: if signedIn();
      allow create: if signedIn() && (request.auth.uid == pid || isAdmin());
      allow update: if isAdmin() || (request.auth.uid == pid && request.resource.data.active == resource.data.active);
      allow delete: if isAdmin();
    }

    match /seasons/{sid} {
      allow read: if signedIn();
      allow write: if isAdmin();
    }

    // matches: any player may create a shared match; only admin edits/merges/locks
    match /matches/{mid} {
      allow read: if signedIn();
      allow create: if signedIn() && request.resource.data.createdBy == request.auth.uid;
      allow update, delete: if isAdmin();
    }

    match /performances/{perfId} {
      allow read: if signedIn();   // needed for team stats & leaderboards
      allow create: if signedIn()
        && request.resource.data.playerId == request.auth.uid
        && request.resource.data.status == 'PENDING';
      allow update: if isAdmin() || (
        signedIn() && resource.data.playerId == request.auth.uid
        && resource.data.status != 'LOCKED'
        && request.resource.data.playerId == request.auth.uid
        && request.resource.data.status == resource.data.status);   // cannot self-verify
      allow delete: if isAdmin() || (
        signedIn() && resource.data.playerId == request.auth.uid
        && resource.data.status != 'LOCKED');
    }

    match /awards/{aid} {
      allow read: if signedIn();
      allow write: if isAdmin();
    }
  }
}

RACC_EOF
mkdir -p "$(dirname 'RashidAbbasCC/gradle.properties')"
cat > 'RashidAbbasCC/gradle.properties' << 'RACC_EOF'
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
android.useAndroidX=true
kotlin.code.style=official
android.nonTransitiveRClass=true

RACC_EOF
mkdir -p "$(dirname 'RashidAbbasCC/settings.gradle.kts')"
cat > 'RashidAbbasCC/settings.gradle.kts' << 'RACC_EOF'
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}
rootProject.name = "RashidAbbasCC"
include(":app")

RACC_EOF
echo "Done. Project created in RashidAbbasCC/ — cd RashidAbbasCC to continue."
