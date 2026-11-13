# Firebase integration boundary

FCM is deferred. No Firebase project, SDK, device token registration or notification job exists in Phase 1. Later configure a separate development project and Android application ID. Keep Google service-account credentials server-side and outside Git. Platform configuration files are ignored pending project setup. Laravel alone sends push notifications through queued jobs.
