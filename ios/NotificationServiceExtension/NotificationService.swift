import UserNotifications

/// Notification Service Extension that downloads and attaches media
/// (profile photos, avatars) to push notifications for rich display.
class NotificationService: UNNotificationServiceExtension {

    private var contentHandler: ((UNNotificationContent) -> Void)?
    private var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        guard let bestAttemptContent = bestAttemptContent else {
            contentHandler(request.content)
            return
        }

        // Look for image URL in the FCM payload
        let imageUrlString = bestAttemptContent.userInfo["imageUrl"] as? String
            ?? (bestAttemptContent.userInfo["fcm_options"] as? [String: Any])?["image"] as? String

        guard let urlString = imageUrlString, let url = URL(string: urlString) else {
            contentHandler(bestAttemptContent)
            return
        }

        downloadImage(from: url) { attachment in
            if let attachment = attachment {
                bestAttemptContent.attachments = [attachment]
            }
            contentHandler(bestAttemptContent)
        }
    }

    override func serviceExtensionTimeWillExpire() {
        // Deliver what we have so far if the time limit is reached.
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

    // MARK: - Private

    private func downloadImage(
        from url: URL,
        completion: @escaping (UNNotificationAttachment?) -> Void
    ) {
        let task = URLSession.shared.downloadTask(with: url) { localUrl, response, error in
            guard error == nil,
                  let localUrl = localUrl,
                  let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                completion(nil)
                return
            }

            // Determine file extension from MIME type
            let ext: String
            let mimeType = httpResponse.mimeType ?? ""
            if mimeType.contains("png") {
                ext = "png"
            } else if mimeType.contains("gif") {
                ext = "gif"
            } else {
                ext = "jpg"
            }

            // Move to a temp location with proper extension
            let tempDir = FileManager.default.temporaryDirectory
            let tempFile = tempDir.appendingPathComponent(UUID().uuidString + "." + ext)

            do {
                try FileManager.default.moveItem(at: localUrl, to: tempFile)
                let attachment = try UNNotificationAttachment(
                    identifier: "image",
                    url: tempFile,
                    options: nil
                )
                completion(attachment)
            } catch {
                completion(nil)
            }
        }
        task.resume()
    }
}
