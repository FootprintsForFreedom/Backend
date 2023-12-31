import AppApi
import Vapor

extension HTTPMediaType {
    func mediaFileType() -> Media.Detail.FileType? {
        if let group = Media.Detail.FileType.for("\(type)/\(subType)") {
            return group
        }
        return nil
    }

    var isValidForMedia: Bool {
        mediaFileType() != nil
    }

    func preferredFilenameExtension() -> String? {
        switch "\(type)/\(subType)" {
        case "video/quicktime": return "mov"
        case "video/mpeg": return "mpg"
        case "video/mp4": return "mp4"
        case "audio/mpeg": return "mp3"
        case "audio/vnd.wave", "audio/wave": return "wav"
        case "image/png": return "png"
        case "image/jpeg": return "jpeg"
        case "application/pdf": return "pdf"
        default: return nil
        }
    }
}
