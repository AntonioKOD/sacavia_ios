//
//  CreatePostView.swift
//  SacaviaApp
//
//  Created by Antonio Kodheli on 7/16/25.
//

import SwiftUI
import PhotosUI
import AVKit

struct CreatePostView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var apiService = APIService()
    @StateObject private var authManager = AuthManager.shared
    
    // Camera and media states
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var showVideoPicker = false
    @State private var capturedImage: UIImage?
    @State private var selectedImages: [UIImage] = []
    @State private var selectedVideoData: [Data] = []
    @State private var isProcessingMedia = false
    
    // Form states
    @State private var postContent = ""
    @State private var selectedLocation: SearchLocationData?
    @State private var locationSearchQuery = ""
    @State private var locationSearchResults: [SearchLocationData] = []
    @State private var isSearchingLocations = false
    @State private var showLocationSearch = false
    
    // UI states
    @State private var isSubmitting = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    
    // Camera states
    @State private var camera = CameraController()
    @State private var showCameraView = false
    @State private var capturedMedia: MediaItem?
    
    // Brand colors - Instagram-like light theme
    let primaryColor = Color(red: 255/255, green: 107/255, blue: 107/255) // #FF6B6B
    let secondaryColor = Color(red: 78/255, green: 205/255, blue: 196/255) // #4ECDC4
    let backgroundColor = Color(red: 250/255, green: 250/255, blue: 250/255) // Light background
    let cardBackground = Color.white // Card background
    let borderColor = Color(red: 219/255, green: 219/255, blue: 219/255) // Light border
    
    var body: some View {
        mainContent
            .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhotos, matching: .images)
            .photosPicker(isPresented: $showVideoPicker, selection: $selectedVideos, matching: .videos)
            .onChange(of: selectedPhotos) { _, photos in
                Task {
                    await loadPhotos(from: photos)
                }
            }
            .onChange(of: selectedVideos) { _, videos in
                Task {
                    await loadVideos(from: videos)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .alert("Success", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your post has been shared successfully!")
            }
            .fullScreenCover(isPresented: $showCameraView) {
                cameraSheetContent
            }
    }
    
    private var mainContent: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    headerSection
                    mediaSection
                    contentSection
                    locationSection
                    submitSection
                }
            }
            .background(backgroundColor)
            .navigationTitle("Create Post")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.black)
                    .font(.system(size: 16, weight: .medium))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Share") {
                        submitPost()
                    }
                    .foregroundColor(isSubmitDisabled ? .gray : primaryColor)
                    .font(.system(size: 16, weight: .semibold))
                    .disabled(isSubmitDisabled)
                }
            }
        }
    }
    
    private var cameraSheetContent: some View {
        Group {
            if let capturedMedia = capturedMedia {
                ZStack {
                    Color.black.ignoresSafeArea()
                    
                    VStack {
                        mediaDisplay(for: capturedMedia)
                        
                        HStack(spacing: 20) {
                            Button("Retake") {
                                self.capturedMedia = nil
                            }
                            .foregroundColor(.white)
                            .padding()
                            
                            Button("Use Photo") {
                                if let image = capturedMedia.image {
                                    selectedImages.append(image)
                                } else if let videoURL = capturedMedia.videoURL,
                                          let videoData = try? Data(contentsOf: videoURL) {
                                    selectedVideoData.append(videoData)
                                }
                                self.capturedMedia = nil
                                showCameraView = false
                            }
                            .foregroundColor(.white)
                            .padding()
                        }
                        .padding()
                    }
                }
            } else {
                // Use a simpler camera implementation that definitely works
                SimpleCameraView { media in
                    self.capturedMedia = media
                }
            }
        }
    }
    
    private func mediaDisplay(for media: MediaItem) -> some View {
        Group {
            switch media.type {
            case .image:
                if let image = media.image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            case .video:
                if let videoURL = media.videoURL {
                    VideoPlayer(player: AVPlayer(url: videoURL))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
    }
    
    // MARK: - Instagram-like UI Sections
    
    private var headerSection: some View {
        HStack {
            // Profile image placeholder
            Circle()
                .fill(backgroundColor)
                .stroke(borderColor, lineWidth: 1)
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "person.fill")
                        .foregroundColor(.gray)
                        .font(.system(size: 18))
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Share to your story")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                Text("Your followers can see this")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(cardBackground)
    }
    
    private var mediaSection: some View {
        VStack(spacing: 16) {
            if selectedImages.isEmpty && selectedVideoData.isEmpty {
                // Media picker buttons
                VStack(spacing: 20) {
                    Text("Add photos or videos")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.black)
                    
                    HStack(spacing: 20) {
                        Button(action: { showPhotoPicker = true }) {
                            VStack(spacing: 8) {
                                Image(systemName: "photo.on.rectangle")
                                    .font(.system(size: 32))
                                    .foregroundColor(primaryColor)
                                Text("Photo")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.black)
                            }
                            .frame(width: 80, height: 80)
                            .background(cardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(borderColor, lineWidth: 1)
                            )
                            .cornerRadius(12)
                        }
                        
                        Button(action: { showVideoPicker = true }) {
                            VStack(spacing: 8) {
                                Image(systemName: "video.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(secondaryColor)
                                Text("Video")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.black)
                            }
                            .frame(width: 80, height: 80)
                            .background(cardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(borderColor, lineWidth: 1)
                            )
                            .cornerRadius(12)
                        }
                        
                        Button(action: { showCameraView = true }) {
                            VStack(spacing: 8) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.black)
                                Text("Camera")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.black)
                            }
                            .frame(width: 80, height: 80)
                            .background(cardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(borderColor, lineWidth: 1)
                            )
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(.vertical, 40)
            } else {
                // Selected media preview
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 120, height: 120)
                                    .clipped()
                                    .cornerRadius(12)
                                
                                Button(action: {
                                    selectedImages.remove(at: index)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.white)
                                        .background(Color.black.opacity(0.6))
                                        .clipShape(Circle())
                                }
                                .padding(6)
                            }
                        }
                        
                        // Add more button
                        Button(action: { showPhotoPicker = true }) {
                            VStack(spacing: 8) {
                                Image(systemName: "plus")
                                    .font(.system(size: 24))
                                    .foregroundColor(primaryColor)
                                Text("Add More")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.black)
                            }
                            .frame(width: 120, height: 120)
                            .background(cardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(borderColor, lineWidth: 1)
                            )
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .background(cardBackground)
    }
    
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Write a caption...", text: $postContent, axis: .vertical)
                .font(.system(size: 16))
                .lineLimit(5...10)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(borderColor, lineWidth: 1)
                )
                .cornerRadius(8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(backgroundColor)
    }
    
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                showLocationInput.toggle()
            }) {
                HStack {
                    Image(systemName: "location")
                        .foregroundColor(primaryColor)
                    Text(selectedLocation?.name ?? "Add location")
                        .foregroundColor(.black)
                        .font(.system(size: 16))
                    Spacer()
                    Image(systemName: showLocationInput ? "chevron.up" : "chevron.down")
                        .foregroundColor(.gray)
                        .font(.system(size: 14))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(borderColor, lineWidth: 1)
                )
                .cornerRadius(8)
            }
            
            if showLocationInput {
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Search for a location...", text: $locationSearchQuery)
                        .font(.system(size: 16))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(borderColor, lineWidth: 1)
                        )
                        .cornerRadius(8)
                        .onChange(of: locationSearchQuery) { _, query in
                            if query.count >= 2 {
                                searchLocations(query: query)
                            } else {
                                locationSearchResults = []
                            }
                        }
                    
                    if isSearchingLocations {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Searching...")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal, 16)
                    } else if !locationSearchResults.isEmpty {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(locationSearchResults) { location in
                                Button(action: {
                                    selectedLocation = location
                                    locationSearchQuery = location.name
                                    locationSearchResults = []
                                    showLocationInput = false
                                }) {
                                    HStack {
                                        Image(systemName: "location.fill")
                                            .foregroundColor(primaryColor)
                                            .font(.system(size: 14))
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(location.name)
                                                .font(.system(size: 15, weight: .medium))
                                                .foregroundColor(.black)
                                            Text(location.address)
                                                .font(.system(size: 13))
                                                .foregroundColor(.gray)
                                        }
                                        Spacer()
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                }
                                
                                if location.id != locationSearchResults.last?.id {
                                    Divider()
                                        .padding(.horizontal, 16)
                                }
                            }
                        }
                        .background(cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(borderColor, lineWidth: 1)
                        )
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .background(backgroundColor)
    }
    
    private var submitSection: some View {
        VStack(spacing: 16) {
            // Additional options
            HStack(spacing: 20) {
                Button(action: {}) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(primaryColor)
                        Text("Tag People")
                            .foregroundColor(.black)
                            .font(.system(size: 16))
                    }
                }
                
                Spacer()
                
                Button(action: {}) {
                    HStack(spacing: 8) {
                        Image(systemName: "facebook")
                            .foregroundColor(.blue)
                        Text("Share to Facebook")
                            .foregroundColor(.black)
                            .font(.system(size: 16))
                    }
                }
            }
            .padding(.horizontal, 16)
            
            // Share button
            Button(action: submitPost) {
                HStack {
                    if isSubmitting {
                        ProgressView()
                            .scaleEffect(0.8)
                            .foregroundColor(.white)
                    }
                    Text(isSubmitting ? "Sharing..." : "Share")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    Group {
                        if isSubmitDisabled {
                            Color.gray.opacity(0.3)
                        } else {
                            LinearGradient(
                                colors: [primaryColor, secondaryColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        }
                    }
                )
                .cornerRadius(12)
            }
            .disabled(isSubmitDisabled)
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
        .background(backgroundColor)
    }
    
    // MARK: - Section Extraction for Type-Checking
    
    private var cameraPreviewSection: some View {
        ZStack {
            if let capturedMedia = capturedMedia {
                // Show captured media
                switch capturedMedia.type {
                case .image:
                    if let image = capturedMedia.image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
                    }
                case .video:
                    if let videoURL = capturedMedia.videoURL {
                        VideoPlayer(player: AVPlayer(url: videoURL))
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
                    }
                }
                // Media controls overlay
                VStack {
                    HStack {
                        Button("Retake") {
                            self.capturedMedia = nil
                            showCameraView = true
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(25)
                        .font(.system(size: 16, weight: .medium))
                        Spacer()
                        Button("Use") {
                            if let image = capturedMedia.image {
                                selectedImages.append(image)
                            } else if let videoURL = capturedMedia.videoURL,
                                      let videoData = try? Data(contentsOf: videoURL) {
                                selectedVideoData.append(videoData)
                            }
                            self.capturedMedia = nil
                            showLocationInput = true
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [primaryColor, secondaryColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(25)
                        .font(.system(size: 16, weight: .semibold))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    Spacer()
                }
            } else if showCameraView {
                CameraView(camera: camera) { media in
                    self.capturedMedia = media
                    showCameraView = false
                }
            } else {
                VStack(spacing: 40) {
                    Spacer()
                    Button(action: {
                        showCameraView = true
                    }) {
                        VStack(spacing: 20) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [primaryColor, secondaryColor],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 120, height: 120)
                                    .shadow(color: primaryColor.opacity(0.3), radius: 20, x: 0, y: 10)
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 48, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            Text("Tap to capture")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    Spacer()
                    HStack(spacing: 30) {
                        Button(action: {
                            showPhotoPicker = true
                        }) {
                            VStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(cardBackground)
                                        .frame(width: 60, height: 60)
                                    Image(systemName: "photo.on.rectangle")
                                        .font(.system(size: 24, weight: .medium))
                                        .foregroundColor(primaryColor)
                                }
                                Text("Gallery")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        }
                        Button(action: {
                            showVideoPicker = true
                        }) {
                            VStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(cardBackground)
                                        .frame(width: 60, height: 60)
                                    Image(systemName: "video")
                                        .font(.system(size: 24, weight: .medium))
                                        .foregroundColor(secondaryColor)
                                }
                                Text("Video")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.bottom, 60)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var contentInputSection: some View {
        VStack(spacing: 20) {
            // Media preview
            if !selectedImages.isEmpty || !selectedVideoData.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 100, height: 100)
                                    .clipped()
                                    .cornerRadius(16)
                                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                                Button(action: {
                                    selectedImages.remove(at: index)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.white)
                                        .background(Color.black.opacity(0.6))
                                        .clipShape(Circle())
                                }
                                .padding(6)
                            }
                        }
                        ForEach(Array(selectedVideoData.enumerated()), id: \.offset) { index, _ in
                            ZStack(alignment: .topTrailing) {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(cardBackground)
                                    .frame(width: 100, height: 100)
                                    .overlay(
                                        VStack(spacing: 8) {
                                            Image(systemName: "video.fill")
                                                .font(.system(size: 24))
                                                .foregroundColor(secondaryColor)
                                            Text("Video")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    )
                                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                                Button(action: {
                                    selectedVideoData.remove(at: index)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.white)
                                        .background(Color.black.opacity(0.6))
                                        .clipShape(Circle())
                                }
                                .padding(6)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 10)
            }
            // Content input
            VStack(alignment: .leading, spacing: 12) {
                Text("What's on your mind?")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                TextField("Share your experience...", text: $postContent, axis: .vertical)
                    .textFieldStyle(CustomTextFieldStyle())
                    .lineLimit(3...6)
            }
            .padding(.horizontal, 20)
            // Location search
            if showLocationInput {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(primaryColor)
                        Text("Add location")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    TextField("Search for a location...", text: $locationSearchQuery)
                        .textFieldStyle(CustomTextFieldStyle())
                        .onChange(of: locationSearchQuery) { _, query in
                            if query.count >= 2 {
                                searchLocations(query: query)
                            } else {
                                locationSearchResults = []
                            }
                        }
                    if isSearchingLocations {
                        HStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(primaryColor)
                            Text("Searching...")
                                .foregroundColor(.gray)
                                .font(.subheadline)
                        }
                        .padding(.vertical, 8)
                    } else if !locationSearchResults.isEmpty {
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 8) {
                                ForEach(locationSearchResults) { location in
                                    Button(action: {
                                        selectedLocation = location
                                        locationSearchQuery = location.name
                                        locationSearchResults = []
                                    }) {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(location.name)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundColor(.white)
                                            Text(location.address)
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 16)
                                    }
                                    .background(cardBackground)
                                    .cornerRadius(12)
                                }
                            }
                        }
                        .frame(maxHeight: 200)
                    }
                    if let selectedLocation = selectedLocation {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(secondaryColor)
                            Text("📍 \(selectedLocation.name)")
                                .foregroundColor(.white)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            Button("Remove") {
                                self.selectedLocation = nil
                                locationSearchQuery = ""
                            }
                            .foregroundColor(primaryColor)
                            .font(.subheadline)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(cardBackground)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 20)
            }
            // Submit button
            Button(action: submitPost) {
                HStack(spacing: 12) {
                    if isSubmitting {
                        ProgressView()
                            .scaleEffect(0.8)
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                    }
                    Text(isSubmitting ? "Sharing..." : "Share Post")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    Group {
                        if isSubmitDisabled {
                            Color.gray.opacity(0.3)
                        } else {
                            LinearGradient(
                                colors: [primaryColor, secondaryColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        }
                    }
                )
                .cornerRadius(25)
                .shadow(color: isSubmitDisabled ? .clear : primaryColor.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .disabled(isSubmitDisabled)
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .background(backgroundColor)
        .transition(.move(edge: .bottom))
    }
    
    private var shouldShowContentInput: Bool {
        !selectedImages.isEmpty || !selectedVideoData.isEmpty || showLocationInput
    }
    
    // MARK: - Computed Properties
    
    private var isSubmitDisabled: Bool {
        postContent.isEmpty && selectedImages.isEmpty && selectedVideoData.isEmpty || isSubmitting
    }
    
    // MARK: - State Variables
    
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var selectedVideos: [PhotosPickerItem] = []
    @State private var showLocationInput = false
    
    // MARK: - Helper Methods
    
    private func searchLocations(query: String) {
        isSearchingLocations = true
        
        Task {
            do {
                let results = try await apiService.searchLocations(query: query)
                await MainActor.run {
                    locationSearchResults = results
                    isSearchingLocations = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isSearchingLocations = false
                }
            }
        }
    }
    
    private func loadPhotos(from items: [PhotosPickerItem]) async {
        print("📱 CreatePostView: Loading \(items.count) photos")
        isProcessingMedia = true
        
        for (index, item) in items.enumerated() {
            print("📱 Processing photo \(index + 1)")
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                print("📱 Successfully loaded photo \(index + 1): \(image.size.width) x \(image.size.height)")
                await MainActor.run {
                    selectedImages.append(image)
                    print("📱 Added photo to selectedImages. Total: \(selectedImages.count)")
                }
            } else {
                print("📱 Failed to load photo \(index + 1)")
            }
        }
        
        await MainActor.run {
            isProcessingMedia = false
            showLocationInput = true
            print("📱 Photo loading complete. Total images: \(selectedImages.count)")
        }
    }
    
    private func loadVideos(from items: [PhotosPickerItem]) async {
        print("📱 CreatePostView: Loading \(items.count) videos")
        isProcessingMedia = true
        
        for (index, item) in items.enumerated() {
            print("📱 Processing video \(index + 1)")
            if let data = try? await item.loadTransferable(type: Data.self) {
                print("📱 Successfully loaded video \(index + 1): \(data.count) bytes")
                await MainActor.run {
                    selectedVideoData.append(data)
                    print("📱 Added video to selectedVideoData. Total: \(selectedVideoData.count)")
                }
            } else {
                print("📱 Failed to load video \(index + 1)")
            }
        }
        
        await MainActor.run {
            isProcessingMedia = false
            showLocationInput = true
            print("📱 Video loading complete. Total videos: \(selectedVideoData.count)")
        }
    }
    
    private func submitPost() {
        guard !postContent.isEmpty || !selectedImages.isEmpty || !selectedVideoData.isEmpty else {
            errorMessage = "Please add some content to your post"
            showError = true
            return
        }
        
        // DEBUG: Log media state before submission
        print("📱 CreatePostView: Submitting post with:")
        print("   - Content length: \(postContent.count)")
        print("   - Selected images: \(selectedImages.count)")
        print("   - Selected videos: \(selectedVideoData.count)")
        print("   - Location: \(selectedLocation?.name ?? "None")")
        
        // Check authentication state
        print("📱 CreatePostView: Authentication state:")
        print("   - AuthManager isAuthenticated: \(authManager.isAuthenticated)")
        print("   - AuthManager token exists: \(authManager.token != nil)")
        print("   - AuthManager token: \(authManager.token?.prefix(20) ?? "None")")
        print("   - AuthManager user: \(authManager.user?.name ?? "None")")
        
        // Validate that we have media if content is empty
        if postContent.isEmpty && selectedImages.isEmpty && selectedVideoData.isEmpty {
            errorMessage = "Please add some content or media to your post"
            showError = true
            return
        }
        
        // Check if user is authenticated
        guard authManager.isAuthenticated else {
            errorMessage = "Please log in to create a post"
            showError = true
            return
        }
        
        isSubmitting = true
        
        Task {
            do {
                // Ensure user is authenticated
                try apiService.ensureAuthenticated()
                
                // DEBUG: Log media details
                for (index, image) in selectedImages.enumerated() {
                    print("📱 Image \(index + 1): \(image.size.width) x \(image.size.height)")
                }
                
                for (index, videoData) in selectedVideoData.enumerated() {
                    print("📱 Video \(index + 1): \(videoData.count) bytes")
                }
                
                let success = try await apiService.createPost(
                    content: postContent.isEmpty ? "Shared from Sacavia" : postContent, // Ensure we always have content
                    locationId: selectedLocation?.id,
                    locationName: selectedLocation?.name,
                    images: selectedImages,
                    videos: selectedVideoData,
                    progressHandler: { progress in
                        // Update UI with upload progress
                        Task { @MainActor in
                            // You can add a progress indicator here if needed
                            print("📱 Upload progress: \(Int(progress * 100))%")
                        }
                    }
                )
                
                await MainActor.run {
                    isSubmitting = false
                    if success {
                        showSuccess = true
                    } else {
                        errorMessage = "Failed to create post. Please try again."
                        showError = true
                    }
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

// MARK: - Custom Text Field Style

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(red: 25/255, green: 25/255, blue: 25/255))
            .cornerRadius(12)
            .foregroundColor(.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
    }
}

// MARK: - Supporting Views and Models

struct CameraView: UIViewControllerRepresentable {
    let camera: CameraController
    let onCapture: (MediaItem) -> Void
    
    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        controller.camera = camera
        controller.onCapture = onCapture
        
        // Set up camera callbacks
        camera.onPhotoCaptured = { [weak controller] image in
            let mediaItem = MediaItem(type: .image, image: image, videoURL: nil)
            controller?.onCapture(mediaItem)
        }
        
        camera.onVideoCaptured = { [weak controller] videoURL in
            let mediaItem = MediaItem(type: .video, image: nil, videoURL: videoURL)
            controller?.onCapture(mediaItem)
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        // Update the camera controller reference
        uiViewController.camera = camera
        uiViewController.onCapture = onCapture
    }
}

// Simple, reliable camera implementation
struct SimpleCameraView: UIViewControllerRepresentable {
    let onCapture: (MediaItem) -> Void
    
    func makeUIViewController(context: Context) -> SimpleCameraViewController {
        let controller = SimpleCameraViewController()
        controller.onCapture = onCapture
        return controller
    }
    
    func updateUIViewController(_ uiViewController: SimpleCameraViewController, context: Context) {
        uiViewController.onCapture = onCapture
    }
}

class SimpleCameraViewController: UIViewController {
    var onCapture: ((MediaItem) -> Void)!
    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var photoOutput: AVCapturePhotoOutput!
    private var videoOutput: AVCaptureMovieFileOutput!
    private var currentCameraInput: AVCaptureDeviceInput?
    private var isRecording = false
    
    // UI Elements
    private var modeSegmentedControl: UISegmentedControl!
    private var captureButton: UIButton!
    private var outerRing: UIView!
    private var innerCircle: UIView!
    private var recordingIndicator: UIView!
    private var closeButton: UIButton!
    private var flipButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession.startRunning()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }
    
    private func setupCamera() {
        print("📷 Setting up camera session")
        
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .high
        
        // Request camera permission
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    self?.configureCameraSession()
                } else {
                    print("📷 Camera permission denied")
                }
            }
        }
    }
    
    private func configureCameraSession() {
        captureSession.beginConfiguration()
        
        // Add camera input
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            print("📷 Failed to create camera input")
            captureSession.commitConfiguration()
            return
        }
        
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
            currentCameraInput = input
            print("📷 Camera input added successfully")
        }
        
        // Add photo output
        photoOutput = AVCapturePhotoOutput()
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
            print("📷 Photo output added successfully")
        }
        
        // Add video output
        videoOutput = AVCaptureMovieFileOutput()
        
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
            print("📷 Video output added successfully")
            
            // Configure video output settings for better compatibility (after adding to session)
            if let connection = videoOutput.connection(with: .video) {
                if connection.isVideoStabilizationSupported {
                    connection.preferredVideoStabilizationMode = .auto
                    print("📷 Video stabilization enabled")
                }
            }
            
            // Set maximum recording duration (optional - prevents very long recordings)
            videoOutput.maxRecordedDuration = CMTime(seconds: 300, preferredTimescale: 1) // 5 minutes max
            print("📷 Maximum recording duration set to 5 minutes")
            
        } else {
            print("📷 Failed to add video output to session")
        }
        
        captureSession.commitConfiguration()
        
        // Setup preview layer
        setupPreviewLayer()
        
        // Start session
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.captureSession.startRunning()
            print("📷 Camera session started")
        }
    }
    
    private func setupPreviewLayer() {
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.insertSublayer(previewLayer, at: 0)
        print("📷 Preview layer setup complete")
    }
    
    private func setupUI() {
        print("📷 Setting up camera UI")
        
        // Setup close button
        setupCloseButton()
        
        // Setup mode selector
        setupModeSelector()
        
        // Setup flip button
        setupFlipButton()
        
        // Setup capture button
        setupCaptureButton()
    }
    
    private func setupCloseButton() {
        closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .white
        closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        closeButton.layer.cornerRadius = 20
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        view.addSubview(closeButton)
        
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            closeButton.widthAnchor.constraint(equalToConstant: 40),
            closeButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    private func setupModeSelector() {
        modeSegmentedControl = UISegmentedControl(items: ["Photo", "Video"])
        modeSegmentedControl.selectedSegmentIndex = 0
        modeSegmentedControl.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        modeSegmentedControl.selectedSegmentTintColor = .white
        modeSegmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
        modeSegmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.black], for: .selected)
        modeSegmentedControl.layer.cornerRadius = 16
        modeSegmentedControl.addTarget(self, action: #selector(modeChanged), for: .valueChanged)
        view.addSubview(modeSegmentedControl)
        
        modeSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            modeSegmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            modeSegmentedControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            modeSegmentedControl.widthAnchor.constraint(equalToConstant: 120),
            modeSegmentedControl.heightAnchor.constraint(equalToConstant: 32)
        ])
    }
    
    private func setupFlipButton() {
        flipButton = UIButton(type: .system)
        flipButton.setImage(UIImage(systemName: "camera.rotate"), for: .normal)
        flipButton.tintColor = .white
        flipButton.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        flipButton.layer.cornerRadius = 20
        flipButton.addTarget(self, action: #selector(flipButtonTapped), for: .touchUpInside)
        view.addSubview(flipButton)
        
        flipButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            flipButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            flipButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            flipButton.widthAnchor.constraint(equalToConstant: 40),
            flipButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    private func setupCaptureButton() {
        // Outer ring
        outerRing = UIView()
        outerRing.backgroundColor = UIColor.clear
        outerRing.layer.borderWidth = 4
        outerRing.layer.borderColor = UIColor.white.cgColor
        outerRing.layer.cornerRadius = 40
        view.addSubview(outerRing)
        
        // Inner circle
        innerCircle = UIView()
        innerCircle.backgroundColor = .white
        innerCircle.layer.cornerRadius = 30
        innerCircle.layer.shadowColor = UIColor.black.cgColor
        innerCircle.layer.shadowOffset = CGSize(width: 0, height: 2)
        innerCircle.layer.shadowOpacity = 0.3
        innerCircle.layer.shadowRadius = 4
        view.addSubview(innerCircle)
        
        // Capture button
        captureButton = UIButton()
        captureButton.backgroundColor = .clear
        captureButton.addTarget(self, action: #selector(captureButtonTapped), for: .touchUpInside)
        view.addSubview(captureButton)
        
        // Layout constraints
        outerRing.translatesAutoresizingMaskIntoConstraints = false
        innerCircle.translatesAutoresizingMaskIntoConstraints = false
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Outer ring
            outerRing.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            outerRing.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            outerRing.widthAnchor.constraint(equalToConstant: 80),
            outerRing.heightAnchor.constraint(equalToConstant: 80),
            
            // Inner circle
            innerCircle.centerXAnchor.constraint(equalTo: outerRing.centerXAnchor),
            innerCircle.centerYAnchor.constraint(equalTo: outerRing.centerYAnchor),
            innerCircle.widthAnchor.constraint(equalToConstant: 60),
            innerCircle.heightAnchor.constraint(equalToConstant: 60),
            
            // Capture button
            captureButton.centerXAnchor.constraint(equalTo: outerRing.centerXAnchor),
            captureButton.centerYAnchor.constraint(equalTo: outerRing.centerYAnchor),
            captureButton.widthAnchor.constraint(equalToConstant: 80),
            captureButton.heightAnchor.constraint(equalToConstant: 80)
        ])
    }
    
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func captureButtonTapped() {
        if modeSegmentedControl.selectedSegmentIndex == 0 {
            // Photo mode
            capturePhoto()
        } else {
            // Video mode
            if isRecording {
                stopRecording()
            } else {
                startRecording()
            }
        }
    }
    
    @objc private func modeChanged() {
        // Update UI based on mode
        if modeSegmentedControl.selectedSegmentIndex == 0 {
            // Photo mode
            innerCircle.backgroundColor = .white
            if isRecording {
                stopRecording()
            }
        } else {
            // Video mode
            innerCircle.backgroundColor = .red
        }
    }
    
    private func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Add button animation
        UIView.animate(withDuration: 0.1, animations: {
            self.innerCircle.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.innerCircle.transform = .identity
            }
        }
    }
    
    private func startRecording() {
        // Check if already recording
        if isRecording || videoOutput.isRecording {
            print("📷 Already recording, ignoring start request")
            return
        }
        
        // Check if session is running
        guard captureSession.isRunning else {
            print("📷 Camera session is not running, cannot start recording")
            return
        }
        
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { 
            print("📷 Failed to get documents directory")
            return 
        }
        
        // Generate unique filename with timestamp and UUID for extra uniqueness
        let timestamp = Date().timeIntervalSince1970
        let uuid = UUID().uuidString.prefix(8)
        let filename = "video_\(Int(timestamp))_\(uuid).mov"
        let videoURL = documentsPath.appendingPathComponent(filename)
        
        print("📷 Starting video recording to: \(videoURL.path)")
        
        // Ensure the file doesn't already exist (should be very unlikely with UUID)
        if FileManager.default.fileExists(atPath: videoURL.path) {
            do {
                try FileManager.default.removeItem(at: videoURL)
                print("📷 Removed existing video file")
            } catch {
                print("📷 Failed to remove existing video file: \(error)")
                return
            }
        }
        
        // Check if videoOutput is ready
        guard !videoOutput.isRecording else {
            print("📷 Video output is already recording")
            return
        }
        
        videoOutput.startRecording(to: videoURL, recordingDelegate: self)
        isRecording = true
        
        // Update UI for recording
        updateRecordingUI(isRecording: true)
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        print("📷 Video recording started successfully")
    }
    
    private func stopRecording() {
        guard isRecording && videoOutput.isRecording else {
            print("📷 Not currently recording, ignoring stop request")
            return
        }
        
        print("📷 Stopping video recording")
        videoOutput.stopRecording()
        isRecording = false
        
        // Update UI for stopped recording
        updateRecordingUI(isRecording: false)
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    private func updateRecordingUI(isRecording: Bool) {
        if isRecording {
            // Show recording indicator
            if recordingIndicator == nil {
                recordingIndicator = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 12))
                recordingIndicator.center = CGPoint(x: view.bounds.midX, y: view.bounds.maxY - 180)
                recordingIndicator.backgroundColor = .red
                recordingIndicator.layer.cornerRadius = 6
                view.addSubview(recordingIndicator)
            }
            
            // Animate recording indicator
            UIView.animate(withDuration: 1.0, delay: 0, options: [.repeat, .autoreverse], animations: {
                self.recordingIndicator.alpha = 0.3
            })
            
            // Change inner circle to red
            innerCircle.backgroundColor = .red
        } else {
            // Hide recording indicator
            recordingIndicator?.removeFromSuperview()
            recordingIndicator = nil
            
            // Change inner circle back to white
            innerCircle.backgroundColor = .white
        }
    }
    
    @objc private func flipButtonTapped() {
        print("📷 Flipping camera")
        
        guard let currentInput = currentCameraInput else {
            print("📷 No current camera input found")
            return
        }
        
        // Determine new position
        let newPosition: AVCaptureDevice.Position = currentInput.device.position == .back ? .front : .back
        
        // Get new camera device
        guard let newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition),
              let newInput = try? AVCaptureDeviceInput(device: newDevice) else {
            print("📷 Failed to create new camera input")
            return
        }
        
        // Switch cameras
        captureSession.beginConfiguration()
        captureSession.removeInput(currentInput)
        
        if captureSession.canAddInput(newInput) {
            captureSession.addInput(newInput)
            currentCameraInput = newInput
            print("📷 Camera flipped to \(newPosition == .back ? "back" : "front")")
        } else {
            // Fallback to original input if new input fails
            captureSession.addInput(currentInput)
            print("📷 Failed to add new input, reverted to original")
        }
        
        captureSession.commitConfiguration()
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Add visual feedback
        UIView.animate(withDuration: 0.2) {
            self.flipButton.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        } completion: { _ in
            UIView.animate(withDuration: 0.2) {
                self.flipButton.transform = .identity
            }
        }
    }
}

extension SimpleCameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Photo capture error: \(error)")
            return
        }
        
        if let imageData = photo.fileDataRepresentation(),
           let image = UIImage(data: imageData) {
            let mediaItem = MediaItem(type: .image, image: image, videoURL: nil)
            onCapture(mediaItem)
        }
    }
}

extension SimpleCameraViewController: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        DispatchQueue.main.async { [weak self] in
            if let error = error {
                print("📷 Video recording error: \(error)")
                print("📷 Error details: \(error.localizedDescription)")
                
                // Check if it's a file name conflict error
                if let avError = error as? AVError {
                    switch avError.code {
                    case .fileAlreadyExists:
                        print("📷 File already exists error - this should have been handled")
                    case .diskFull:
                        print("📷 Disk full error")
                    case .recordingAlreadyInProgress:
                        print("📷 Recording already in progress")
                    default:
                        print("📷 Other AVError: \(avError.localizedDescription)")
                    }
                }
                return
            }
            
            // Verify the file was actually created and has content
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: outputFileURL.path) {
                do {
                    let attributes = try fileManager.attributesOfItem(atPath: outputFileURL.path)
                    let fileSize = attributes[.size] as? Int64 ?? 0
                    print("📷 Video captured successfully: \(outputFileURL.path)")
                    print("📷 Video file size: \(fileSize) bytes")
                    
                    if fileSize > 0 {
                        let mediaItem = MediaItem(type: .video, image: nil, videoURL: outputFileURL)
                        self?.onCapture(mediaItem)
                    } else {
                        print("📷 Video file is empty!")
                    }
                } catch {
                    print("📷 Error checking video file attributes: \(error)")
                }
            } else {
                print("📷 Video file was not created at expected location: \(outputFileURL.path)")
            }
        }
    }
}

struct MediaItem {
    enum MediaType {
        case image
        case video
    }
    
    let type: MediaType
    let image: UIImage?
    let videoURL: URL?
}

// MARK: - Camera Controller

class CameraController: NSObject, ObservableObject {
    @Published var isSessionRunning = false
    @Published var isAuthorized = false
    
    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let videoOutput = AVCaptureMovieFileOutput()
    var videoDeviceInput: AVCaptureDeviceInput?
    var onPhotoCaptured: ((UIImage) -> Void)?
    var onVideoCaptured: ((URL) -> Void)?
    
    override init() {
        super.init()
        checkAuthorization()
    }
    
    func checkAuthorization() {
        print("📱 CameraController: Checking authorization")
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            print("📱 CameraController: Camera authorized")
            isAuthorized = true
            setupSession()
        case .notDetermined:
            print("📱 CameraController: Requesting camera access")
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    print("📱 CameraController: Camera access \(granted ? "granted" : "denied")")
                    self?.isAuthorized = granted
                    if granted {
                        self?.setupSession()
                    }
                }
            }
        default:
            print("📱 CameraController: Camera access denied")
            isAuthorized = false
        }
    }
    
    private func setupSession() {
        print("📱 CameraController: Setting up session")
        session.beginConfiguration()
        
        // Add video input
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            print("📱 CameraController: Failed to get video device or input")
            return
        }
        
        print("📱 CameraController: Video device found")
        
        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
            videoDeviceInput = videoInput
            print("📱 CameraController: Video input added")
        } else {
            print("📱 CameraController: Failed to add video input")
        }
        
        // Add photo output
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            print("📱 CameraController: Photo output added")
        } else {
            print("📱 CameraController: Failed to add photo output")
        }
        
        // Add video output
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
            print("📱 CameraController: Video output added")
        } else {
            print("📱 CameraController: Failed to add video output")
        }
        
        session.commitConfiguration()
        print("📱 CameraController: Session configuration committed")
        
        // Don't start the session here - let the view controller handle it
        print("📱 CameraController: Session configured, ready to start")
    }
    
    func capturePhoto() {
        print("📱 Camera: Capturing photo")
        guard session.isRunning else {
            print("📱 Camera: Session not running, cannot capture photo")
            return
        }
        
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func startRecording() {
        print("📱 Camera: Starting video recording")
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let videoURL = documentsPath.appendingPathComponent("captured_video.mov")
        videoOutput.startRecording(to: videoURL, recordingDelegate: self)
    }
    
    func stopRecording() {
        print("📱 Camera: Stopping video recording")
        videoOutput.stopRecording()
    }
}

extension CameraController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("📱 Camera: Photo capture error: \(error)")
            return
        }
        
        if let imageData = photo.fileDataRepresentation(),
           let image = UIImage(data: imageData) {
            print("📱 Camera: Photo captured successfully: \(image.size.width) x \(image.size.height)")
            DispatchQueue.main.async {
                self.onPhotoCaptured?(image)
            }
        } else {
            print("📱 Camera: Failed to create image from photo data")
        }
    }
}

extension CameraController: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("📱 Camera: Video recording error: \(error)")
            return
        }
        
        print("📱 Camera: Video captured successfully: \(outputFileURL)")
        DispatchQueue.main.async {
            self.onVideoCaptured?(outputFileURL)
        }
    }
}

// MARK: - Camera View Controller

class CameraViewController: UIViewController {
    var camera: CameraController!
    var onCapture: ((MediaItem) -> Void)!
    
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var isRecording = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("📱 CameraViewController: viewDidLoad")
        
        // Ensure camera is properly initialized
        if camera == nil {
            camera = CameraController()
        }
        
        setupPreviewLayer()
        setupUI()
        setupCameraCallbacks()
        
        // Start camera session immediately if authorized
        if camera.isAuthorized {
            startCameraSession()
        } else {
            camera.checkAuthorization()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("📱 CameraViewController: viewWillAppear")
        
        // Start camera session when view appears
        if !camera.session.isRunning && camera.isAuthorized {
            startCameraSession()
        } else if !camera.isAuthorized {
            print("📱 CameraViewController: Camera not authorized")
            // Request authorization if not determined
            if AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined {
                AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                    DispatchQueue.main.async {
                        if granted {
                            print("📱 CameraViewController: Camera access granted")
                            self?.camera.isAuthorized = true
                            self?.startCameraSession()
                        } else {
                            print("📱 CameraViewController: Camera access denied")
                        }
                    }
                }
            }
        }
    }
    
    private func startCameraSession() {
        print("📱 CameraViewController: Starting camera session")
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.camera.session.startRunning()
            DispatchQueue.main.async {
                print("📱 CameraViewController: Camera session started")
                self?.camera.isSessionRunning = true
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("📱 CameraViewController: viewWillDisappear")
        
        // Stop camera session when view disappears
        if camera.session.isRunning {
            camera.session.stopRunning()
            camera.isSessionRunning = false
            print("📱 CameraViewController: Camera session stopped")
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Update preview layer frame
        if let previewLayer = previewLayer {
            previewLayer.frame = view.bounds
        }
    }
    
    private func updateUIPositions() {
        let safeAreaTop = view.safeAreaInsets.top
        let safeAreaBottom = view.safeAreaInsets.bottom
        
        // Update top controls
        if let closeButton = view.subviews.first(where: { $0 is UIButton && $0.frame.origin.x == 20 }) {
            closeButton.frame.origin.y = safeAreaTop + 20
        }
        
        if let flashButton = view.subviews.first(where: { $0 is UIButton && $0.frame.origin.x == view.bounds.maxX - 64 }) {
            flashButton.frame.origin.y = safeAreaTop + 20
        }
        
        if let flipButton = view.subviews.first(where: { $0 is UIButton && $0.frame.origin.y == 120 }) {
            flipButton.frame.origin.y = safeAreaTop + 80
        }
        
        // Update bottom controls
        if let modeControl = view.subviews.first(where: { $0 is UISegmentedControl }) {
            modeControl.frame.origin.y = view.bounds.maxY - safeAreaBottom - 200
        }
        
        if let galleryButton = view.subviews.first(where: { $0 is UIButton && $0.frame.origin.x == view.bounds.maxX - 64 && $0.frame.origin.y == view.bounds.maxY - 200 }) {
            galleryButton.frame.origin.y = view.bounds.maxY - safeAreaBottom - 200
        }
        
        // Update capture button
        if let captureButton = view.subviews.first(where: { $0 is UIButton && $0.frame.width == 70 }) {
            captureButton.center.y = view.bounds.maxY - safeAreaBottom - 100
        }
        
        if let outerRing = view.subviews.first(where: { $0.frame.width == 90 && $0.layer.borderWidth == 4 }) {
            outerRing.center.y = view.bounds.maxY - safeAreaBottom - 100
        }
        
        if let innerCircle = view.subviews.first(where: { $0.tag == 100 }) {
            innerCircle.center.y = view.bounds.maxY - safeAreaBottom - 100
        }
        
        if let recordingIndicator = view.subviews.first(where: { $0.tag == 101 }) {
            recordingIndicator.center.y = view.bounds.maxY - safeAreaBottom - 100
        }
    }
    
    private func setupPreviewLayer() {
        previewLayer = AVCaptureVideoPreviewLayer(session: camera.session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        
        // Add a subtle gradient overlay for better UI visibility
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = view.bounds
        gradientLayer.colors = [
            UIColor.black.withAlphaComponent(0.3).cgColor,
            UIColor.clear.cgColor,
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.3).cgColor
        ]
        gradientLayer.locations = [0.0, 0.1, 0.9, 1.0]
        view.layer.addSublayer(gradientLayer)
    }
    
    private func setupCameraCallbacks() {
        camera.onPhotoCaptured = { [weak self] image in
            let mediaItem = MediaItem(type: .image, image: image, videoURL: nil)
            self?.onCapture(mediaItem)
        }
        
        camera.onVideoCaptured = { [weak self] videoURL in
            let mediaItem = MediaItem(type: .video, image: nil, videoURL: videoURL)
            self?.onCapture(mediaItem)
        }
    }
    
    private func setupUI() {
        setupTopControls()
        setupBottomControls()
        setupCaptureButton()
        setupRecordingIndicator()
    }
    
    private func setupTopControls() {
        // Close button
        let closeButton = UIButton(frame: CGRect(x: 20, y: 60, width: 44, height: 44))
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .white
        closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        closeButton.layer.cornerRadius = 22
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        view.addSubview(closeButton)
        
        // Flash button
        let flashButton = UIButton(frame: CGRect(x: view.bounds.maxX - 64, y: 60, width: 44, height: 44))
        flashButton.setImage(UIImage(systemName: "bolt.slash"), for: .normal)
        flashButton.tintColor = .white
        flashButton.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        flashButton.layer.cornerRadius = 22
        flashButton.addTarget(self, action: #selector(flashButtonTapped), for: .touchUpInside)
        view.addSubview(flashButton)
        
        // Camera flip button
        let flipButton = UIButton(frame: CGRect(x: view.bounds.maxX - 64, y: 120, width: 44, height: 44))
        flipButton.setImage(UIImage(systemName: "camera.rotate"), for: .normal)
        flipButton.tintColor = .white
        flipButton.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        flipButton.layer.cornerRadius = 22
        flipButton.addTarget(self, action: #selector(flipButtonTapped), for: .touchUpInside)
        view.addSubview(flipButton)
    }
    
    private func setupBottomControls() {
        // Mode selector
        let modeSegmentedControl = UISegmentedControl(items: ["Photo", "Video"])
        modeSegmentedControl.frame = CGRect(x: 20, y: view.bounds.maxY - 200, width: 120, height: 32)
        modeSegmentedControl.selectedSegmentIndex = 0
        modeSegmentedControl.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        modeSegmentedControl.selectedSegmentTintColor = .white
        modeSegmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
        modeSegmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.black], for: .selected)
        modeSegmentedControl.addTarget(self, action: #selector(modeChanged), for: .valueChanged)
        view.addSubview(modeSegmentedControl)
        
        // Gallery button
        let galleryButton = UIButton(frame: CGRect(x: view.bounds.maxX - 64, y: view.bounds.maxY - 200, width: 44, height: 44))
        galleryButton.setImage(UIImage(systemName: "photo.on.rectangle"), for: .normal)
        galleryButton.tintColor = .white
        galleryButton.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        galleryButton.layer.cornerRadius = 22
        galleryButton.addTarget(self, action: #selector(galleryButtonTapped), for: .touchUpInside)
        view.addSubview(galleryButton)
    }
    
    private func setupCaptureButton() {
        // Outer ring with gradient
        let outerRing = UIView(frame: CGRect(x: 0, y: 0, width: 90, height: 90))
        outerRing.center = CGPoint(x: view.bounds.midX, y: view.bounds.maxY - 100)
        outerRing.backgroundColor = .clear
        
        // Create gradient layer for outer ring
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = outerRing.bounds
        gradientLayer.colors = [
            UIColor.white.cgColor,
            UIColor.white.withAlphaComponent(0.8).cgColor,
            UIColor.white.withAlphaComponent(0.6).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.cornerRadius = 45
        outerRing.layer.addSublayer(gradientLayer)
        
        // Add border
        outerRing.layer.borderWidth = 3
        outerRing.layer.borderColor = UIColor.white.withAlphaComponent(0.9).cgColor
        outerRing.layer.cornerRadius = 45
        outerRing.tag = 200 // Tag for outer ring
        view.addSubview(outerRing)
        
        // Capture button with enhanced styling
        let captureButton = UIButton(frame: CGRect(x: 0, y: 0, width: 70, height: 70))
        captureButton.center = CGPoint(x: view.bounds.midX, y: view.bounds.maxY - 100)
        
        // Set solid background color instead of gradient for better touch handling
        captureButton.backgroundColor = .white
        captureButton.layer.cornerRadius = 35
        captureButton.layer.shadowColor = UIColor.black.cgColor
        captureButton.layer.shadowOffset = CGSize(width: 0, height: 6)
        captureButton.layer.shadowOpacity = 0.4
        captureButton.layer.shadowRadius = 12
        captureButton.layer.masksToBounds = false
        
        // Add subtle inner shadow
        captureButton.layer.borderWidth = 1
        captureButton.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        
        // Ensure the button is on top and can receive touches
        captureButton.isUserInteractionEnabled = true
        captureButton.addTarget(self, action: #selector(captureButtonTapped), for: .touchUpInside)
        captureButton.tag = 201 // Tag for capture button
        view.addSubview(captureButton)
        
        // Inner circle for recording indicator with enhanced styling
        let innerCircle = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        innerCircle.center = CGPoint(x: view.bounds.midX, y: view.bounds.maxY - 100)
        innerCircle.backgroundColor = .clear
        innerCircle.layer.cornerRadius = 25
        innerCircle.tag = 100 // Tag for finding later
        view.addSubview(innerCircle)
        
        // Add pulse animation to outer ring
        let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
        pulseAnimation.duration = 2.0
        pulseAnimation.fromValue = 1.0
        pulseAnimation.toValue = 1.05
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = .infinity
        outerRing.layer.add(pulseAnimation, forKey: "pulse")
    }
    
    private func setupRecordingIndicator() {
        // Enhanced recording indicator with animation
        let recordingIndicator = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 16))
        recordingIndicator.center = CGPoint(x: view.bounds.midX - 35, y: view.bounds.maxY - 100)
        
        // Create gradient for recording indicator
        let indicatorGradient = CAGradientLayer()
        indicatorGradient.frame = recordingIndicator.bounds
        indicatorGradient.colors = [
            UIColor.red.cgColor,
            UIColor.red.withAlphaComponent(0.8).cgColor
        ]
        indicatorGradient.startPoint = CGPoint(x: 0, y: 0)
        indicatorGradient.endPoint = CGPoint(x: 1, y: 1)
        indicatorGradient.cornerRadius = 8
        recordingIndicator.layer.addSublayer(indicatorGradient)
        
        recordingIndicator.layer.cornerRadius = 8
        recordingIndicator.layer.shadowColor = UIColor.red.cgColor
        recordingIndicator.layer.shadowOffset = CGSize(width: 0, height: 2)
        recordingIndicator.layer.shadowOpacity = 0.6
        recordingIndicator.layer.shadowRadius = 4
        recordingIndicator.alpha = 0
        recordingIndicator.tag = 101 // Tag for finding later
        view.addSubview(recordingIndicator)
        
        // Add pulse animation for recording indicator
        let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
        pulseAnimation.duration = 1.0
        pulseAnimation.fromValue = 1.0
        pulseAnimation.toValue = 1.2
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = .infinity
        recordingIndicator.layer.add(pulseAnimation, forKey: "recordingPulse")
    }
    
    @objc private func captureButtonTapped() {
        print("📱 CameraViewController: Capture button tapped")
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
        
        // Animate the capture button
        if let captureButton = view.subviews.first(where: { $0.tag == 201 }) {
            UIView.animate(withDuration: 0.1, animations: {
                captureButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            }) { _ in
                UIView.animate(withDuration: 0.1) {
                    captureButton.transform = .identity
                }
            }
        }
        
        // Check if camera session is running
        guard camera.session.isRunning else {
            print("📱 CameraViewController: Camera session not running")
            return
        }
        
        if isRecording {
            print("📱 CameraViewController: Stopping recording")
            camera.stopRecording()
            isRecording = false
            updateRecordingUI(isRecording: false)
        } else {
            // Check current mode from segmented control
            if let modeControl = view.subviews.first(where: { $0 is UISegmentedControl }) as? UISegmentedControl {
                if modeControl.selectedSegmentIndex == 1 {
                    // Video mode
                    print("📱 CameraViewController: Starting video recording")
                    startRecording()
                } else {
                    // Photo mode
                    print("📱 CameraViewController: Capturing photo")
            camera.capturePhoto()
                }
            } else {
                // Default to photo if no mode control found
                print("📱 CameraViewController: Capturing photo (default)")
                camera.capturePhoto()
            }
        }
    }
    
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func flashButtonTapped() {
        // Toggle flash
        print("📱 Camera: Flash button tapped")
    }
    
    @objc private func flipButtonTapped() {
        print("📱 Camera: Flip button tapped")
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Animate the button
        if let flipButton = view.subviews.first(where: { $0 is UIButton && $0.frame.origin.x == view.bounds.maxX - 64 && $0.frame.origin.y == view.safeAreaInsets.top + 80 }) {
            UIView.animate(withDuration: 0.2, animations: {
                flipButton.transform = CGAffineTransform(rotationAngle: .pi)
            }) { _ in
                UIView.animate(withDuration: 0.2) {
                    flipButton.transform = .identity
                }
            }
        }
        
        // Switch camera
        switchCamera()
    }
    
    private func switchCamera() {
        guard let currentInput = camera.session.inputs.first as? AVCaptureDeviceInput else { return }
        
        let newPosition: AVCaptureDevice.Position = currentInput.device.position == .back ? .front : .back
        guard let newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition),
              let newInput = try? AVCaptureDeviceInput(device: newDevice) else { return }
        
        camera.session.beginConfiguration()
        camera.session.removeInput(currentInput)
        
        if camera.session.canAddInput(newInput) {
            camera.session.addInput(newInput)
            camera.videoDeviceInput = newInput
            print("📱 Camera: Switched to \(newPosition == .back ? "back" : "front") camera")
        } else {
            // If we can't add the new input, add back the old one
            camera.session.addInput(currentInput)
            print("📱 Camera: Failed to switch camera")
        }
        
        camera.session.commitConfiguration()
    }
    
    @objc private func galleryButtonTapped() {
        // Open photo picker
        print("📱 Camera: Gallery button tapped")
    }
    
    @objc private func modeChanged(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 1 {
            // Video mode
            startRecording()
        } else {
            // Photo mode
            if isRecording {
                stopRecording()
            }
        }
    }
    
    private func startRecording() {
        isRecording = true
        updateRecordingUI(isRecording: true)
        camera.startRecording()
    }
    
    private func stopRecording() {
        isRecording = false
        updateRecordingUI(isRecording: false)
        camera.stopRecording()
    }
    
    private func updateRecordingUI(isRecording: Bool) {
        if let innerCircle = view.viewWithTag(100) {
            if isRecording {
                // Create gradient for recording state
                let recordingGradient = CAGradientLayer()
                recordingGradient.frame = innerCircle.bounds
                recordingGradient.colors = [
                    UIColor.red.cgColor,
                    UIColor.red.withAlphaComponent(0.8).cgColor
                ]
                recordingGradient.startPoint = CGPoint(x: 0, y: 0)
                recordingGradient.endPoint = CGPoint(x: 1, y: 1)
                recordingGradient.cornerRadius = 25
                
                // Remove existing gradient layers
                innerCircle.layer.sublayers?.forEach { layer in
                    if layer is CAGradientLayer {
                        layer.removeFromSuperlayer()
                    }
                }
                
                innerCircle.layer.addSublayer(recordingGradient)
                innerCircle.layer.shadowColor = UIColor.red.cgColor
                innerCircle.layer.shadowOffset = CGSize(width: 0, height: 2)
                innerCircle.layer.shadowOpacity = 0.6
                innerCircle.layer.shadowRadius = 4
            } else {
                // Clear recording state
                innerCircle.layer.sublayers?.forEach { layer in
                    if layer is CAGradientLayer {
                        layer.removeFromSuperlayer()
                    }
                }
                innerCircle.backgroundColor = .clear
                innerCircle.layer.shadowOpacity = 0
            }
        }
        
        if let recordingIndicator = view.viewWithTag(101) {
            UIView.animate(withDuration: 0.3) {
                recordingIndicator.alpha = isRecording ? 1.0 : 0.0
            }
        }
        
        // Update outer ring animation
        if let outerRing = view.viewWithTag(200) {
            if isRecording {
                // Add more intense pulse animation for recording
                let intensePulse = CABasicAnimation(keyPath: "transform.scale")
                intensePulse.duration = 1.0
                intensePulse.fromValue = 1.0
                intensePulse.toValue = 1.1
                intensePulse.autoreverses = true
                intensePulse.repeatCount = .infinity
                outerRing.layer.add(intensePulse, forKey: "intensePulse")
            } else {
                // Restore normal pulse animation
                let normalPulse = CABasicAnimation(keyPath: "transform.scale")
                normalPulse.duration = 2.0
                normalPulse.fromValue = 1.0
                normalPulse.toValue = 1.05
                normalPulse.autoreverses = true
                normalPulse.repeatCount = .infinity
                outerRing.layer.add(normalPulse, forKey: "pulse")
            }
        }
    }
}

#Preview {
    CreatePostView()
} 