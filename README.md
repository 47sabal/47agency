# SmartPark Nepal 🚗🅿️

An online parking booking platform designed for Nepal's growing cities. Reserve a spot in advance, enter and exit seamlessly through an automatic QR-code voucher, and pay a fair, automatically calculated fee if you overstay.

Developed for the **Everest Engineering College Hackathon 2026** under the **Sustainable City & Mobility** problem track.

---

## 👥 Team: 47Agency
* **Sabal Ghimire**
* **Puranika Khatiwoda**
* **Barsha Chapagain**
* **Shubham Raj Joshi**

---

## 📌 Problem Statement
Cities like Kathmandu were never designed for today's staggering vehicle volume. Modern drivers face severe challenges due to antiquated parking infrastructure:
* **No Guarantee:** Drivers have no way to confirm a spot is available before they arrive, leading to unnecessary cruising and congestion.
* **Long Queues & Manual Overhead:** Most parking facilities depend entirely on a manual attendant issuing paper tickets and collecting cash at the gate.
* **Inconsistent & Slow Billing:** Overstay fees are tracked by hand, making billing slow, error-prone, and hard to trust.

### 💔 Why This Matters
In July 2026, a tragic incident occurred where a young Kathmandu ride-hailing driver lost his life after setting himself on fire following a severe dispute with municipal police regarding a parking violation and wheel-locking near a government office. This incident sparked citywide protests and a parliamentary investigation. It serves as a sobering reminder of how confrontational manual, cash-based parking enforcement can become—and highlights the urgent need for predictable, transparent, and automatic systems for drivers who depend on their vehicles for daily income.

---

## 💡 Proposed Solution
**SmartPark Nepal** removes manual ticketing, cash handling, and guesswork from both ends of the parking experience through a fully automated **Book → Scan → Bill** cycle.

### ✨ Key Features
* **Real-Time Availability:** Live open slots at nearby facilities let drivers reserve a spot and time window in advance.
* **QR Voucher Generation:** Every confirmed booking instantly generates a unique, time-stamped QR code voucher.
* **Automated Gate Access:** Scanning the QR code verifies the booking and automatically triggers entry and exit gates.
* **Automatic Overtime Billing:** Stay duration is automatically tracked against the booked window and billed transparently.
* **Digital Payment Integration:** Seamless integration with popular local payment gateways like **eSewa** and **Khalti** for instant digital payments.
* **Operator Dashboard:** A live administrative view showcasing occupancy rates, real-time bookings, overtime revenue, and gate activity log logs.

---

## 🛠️ Technical Approach & Stack

### Technology Architecture
| Layer | Technology | Purpose |
| :--- | :--- | :--- |
| **Mobile App** | Flutter | Cross-platform driver app for searching, booking, viewing vouchers, and making payments. |
| **Backend** | Node.js | Core booking engine, QR generation/validation, and overtime billing logic. |
| **Database & Auth** | Firebase | Real-time slot availability syncing, booking records database, and user authentication. |
| **Gate Hardware** | ESP32 + QR Scanner + Barrier Relay | Microcontroller setup to read the voucher at entry/exit points and automatically trigger the physical gate. |
| **Payments** | eSewa / Khalti API | Instant digital payment handling for booking fees and overstay charges. |
| **Maps & Analytics**| Google Maps API, Chart.js | Interactive facility search for drivers and visual data analytics for the operator dashboard. |

### 🔄 System Workflow
1. **Book** a slot & time window via the Flutter app.
2. **Receive** a unique, time-stamped QR voucher.
3. **Scan** the QR code at the ESP32-powered gate to enter / exit.
4. **Auto-bill** any overtime duration directly through eSewa/Khalti if the window is exceeded.

---

## 🚀 MVP Scope (Hackathon Deliverables)
* **Driver App Prototype:** User interface for searching nearby facilities, making reservations, and rendering the QR voucher.
* **Booking Engine:** Core reservation logic, real-time slot availability trackers, and QR validation endpoints running on Firebase.
* **Gate Hardware Simulation:** An ESP32 integrated with a physical QR scanner module to demonstrate automatic barrier gate triggering.
* **Overtime Billing Demo:** Automated fee calculation logic that updates the operator dashboard live once a booking window expires.

---

## 📈 Impact & Future Potential

### Target Users
* **Primary:** Private car and bike owners in major urban centers (e.g., Kathmandu Valley) requiring guaranteed parking at malls, hospitals, corporate offices, and event venues.
* **Secondary:** Parking facility operators looking to digitize entry, exit, and administrative billing using low-cost add-ons without replacing existing physical gates.

### Expected Impact
* **Environmental:** Reduces city congestion and carbon footprints as drivers route straight to a confirmed spot instead of circling blocks burning fuel.
* **Social Trust:** Eliminates friction, corruption opportunities, and dangerous disputes by enforcing predictable, transparent, and automated billing rules.
* **Financial Sustainability:** Powered by a multi-stream self-sustaining revenue model including booking service fees, overtime revenue shares, B2B facility subscriptions, and premium driver features.

### 🗺️ Roadmap
* **Phase 1:** Launch pilot locations across strategic high-traffic zones in the Kathmandu Valley.
* **Phase 2:** Scale across commercial hubs, hospitals, and major event venues.
* **Phase 3:** Expand regional footprints to other emerging smart cities in Nepal, such as **Pokhara** and **Biratnagar**, turning SmartPark Nepal into a nationwide public utility
