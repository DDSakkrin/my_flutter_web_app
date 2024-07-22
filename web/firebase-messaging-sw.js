// web/firebase-messaging-sw.js

importScripts('https://www.gstatic.com/firebasejs/8.10.0/firebase-app.js');
importScripts('https://www.gstatic.com/firebasejs/8.10.0/firebase-messaging.js');

firebase.initializeApp({
    apiKey: 'AIzaSyCm8hy_WwmSPlNxO2_53YzTvp1K2D2i6FE',
    appId: '1:292167160200:web:1773f72c7d11524c7bea3d',
    messagingSenderId: '292167160200',
    projectId: 'testcalendar-ec238',
    authDomain: 'testcalendar-ec238.firebaseapp.com',
    databaseURL: 'https://testcalendar-ec238-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'testcalendar-ec238.appspot.com',
    measurementId: 'G-ZFXH1X2P1V',
});

const messaging = firebase.messaging();
