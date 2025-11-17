# Firebase Functions Deploy Instructions

## ⚠️ Important: Blaze Plan Required

Firebase Functions deploy karne ke liye **Blaze (pay-as-you-go) plan** required hai.

## 🚀 Deploy Steps

### Step 1: Upgrade to Blaze Plan
1. Visit: https://console.firebase.google.com/project/laptopsharbor/usage/details
2. Click on "Upgrade project" button
3. Add billing account (credit card required)
4. Wait for upgrade to complete (1-2 minutes)

### Step 2: Deploy Functions
```bash
cd functions
firebase deploy --only functions
```

### Step 3: Verify Deployment
```bash
firebase functions:log
```

## 💰 Blaze Plan Free Tier
- **2 Million** function invocations/month (FREE)
- **400,000 GB-seconds** compute time/month (FREE)
- **5 GB** egress/month (FREE)

Small projects typically stay within free limits!

## 🧪 Alternative: Local Testing (Without Upgrade)
Agar abhi upgrade nahi karna chahte, to locally test kar sakte hain:

```bash
cd functions
npm run serve
```

## 📧 Email Configuration
Gmail credentials already configured:
- Email: samyaghaffar297@gmail.com
- App Password: qzaz wlgk irfn ivmi

## ✅ What Works After Deploy
1. **Order Confirmation Email**: Automatically sent when order is created
2. **Contact Form Email**: Admin notification + User auto-reply

## 🔍 Troubleshooting
- If deploy fails, check Firebase Console for errors
- Verify billing is enabled
- Check Firebase Functions logs: `firebase functions:log`

