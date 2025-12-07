//
//  LostReportFormView.swift
//  LostAndFound
//
//  Created by Craig Bakke on 12/02/25.
//

import SwiftUI
import MapKit
import FirebaseFirestore

struct LostReportFormView: View {
    let currentUserName: String
    let currentUserEmail: String
    
    @State private var selectedCategory: ReportCategory?
    @State private var titleText: String = ""
    @State private var descriptionText: String = ""
    @State private var locationBuilding: String = ""
    @State private var phoneNumber: String = ""
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var mapCameraPosition: MapCameraPosition
    @State private var isMapPickerPresented = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var isShowingAlert = false
    @State private var draftReport: Report?
    @State private var isShowingCamera = false
    @State private var isShowingPhotoPicker = false
    @State private var isSubmitting = false
    @FocusState private var focusedField: Field?
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var imageUploadService = ImageUploadService()
    
    private let titleLimit = 64
    private let descriptionLimit = 1000
    private let locationLimit = 64
    private let phoneLimit = 10
    private let defaultCoordinate = CLLocationCoordinate2D(latitude: 42.33607, longitude: -71.09527)
    private let defaultMapSpan = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.003)
    private let previewMapSpan = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.003)
    
    init(currentUserName: String, currentUserEmail: String) {
        self.currentUserName = currentUserName
        self.currentUserEmail = currentUserEmail
        
        _mapCameraPosition = State(initialValue: .region(MKCoordinateRegion(center: defaultCoordinate, span: defaultMapSpan)))
    }
    
    var body: some View {
        GeometryReader { geometry in
            let horizontalPadding = geometry.size.width * 0.065
            let verticalSpacing = max(geometry.size.height * 0.02, 16)
            let cardCornerRadius = max(geometry.size.width * 0.04, 16)
            let labelFontSize = max(geometry.size.width * 0.045, 17)
            let bodyFontSize = max(geometry.size.width * 0.038, 15)
            let safeBottom = geometry.safeAreaInsets.bottom
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: verticalSpacing) {
                    sectionTitle("Item details", fontSize: labelFontSize * 1.1)
                    
                    card(cornerRadius: cardCornerRadius) {
                        categoryPicker(labelFontSize: labelFontSize, bodyFontSize: bodyFontSize)
                        Divider().overlay(ColorPalette.labelPrimary.opacity(0.1))
                        titleField(labelFontSize: labelFontSize, bodyFontSize: bodyFontSize)
                        Divider().overlay(ColorPalette.labelPrimary.opacity(0.1))
                        descriptionField(labelFontSize: labelFontSize, bodyFontSize: bodyFontSize)
                        Divider().overlay(ColorPalette.labelPrimary.opacity(0.1))
                        imageUploadSection(labelFontSize: labelFontSize, bodyFontSize: bodyFontSize)
                    }
                    
                    sectionTitle("Location", fontSize: labelFontSize * 1.1)
                    
                    card(cornerRadius: cardCornerRadius) {
                        locationBuildingField(labelFontSize: labelFontSize, bodyFontSize: bodyFontSize)
                        Divider().overlay(ColorPalette.labelPrimary.opacity(0.1))
                        locationPickerMap(labelFontSize: labelFontSize, bodyFontSize: bodyFontSize)
                    }
                    
                    sectionTitle("Reporter information", fontSize: labelFontSize * 1.1)
                    
                    card(cornerRadius: cardCornerRadius) {
                        readOnlyField(
                            title: "Name (read-only)",
                            value: currentUserName,
                            labelFontSize: labelFontSize,
                            bodyFontSize: bodyFontSize
                        )
                        
                        Divider().overlay(ColorPalette.labelPrimary.opacity(0.1))
                        
                        readOnlyField(
                            title: "Email (read-only)",
                            value: currentUserEmail,
                            labelFontSize: labelFontSize,
                            bodyFontSize: bodyFontSize
                        )
                        
                        Divider().overlay(ColorPalette.labelPrimary.opacity(0.1))
                        
                        phoneField(labelFontSize: labelFontSize, bodyFontSize: bodyFontSize)
                    }
                    
                    Button {
                        handleSubmit()
                    } label: {
                        submitButtonLabel
                    }
                    .buttonStyle(.plain)
                    .disabled(!isFormSubmittable || isSubmitting)
                    .opacity((isFormSubmittable && !isSubmitting) ? 1 : 0.55)
                    .padding(.top, verticalSpacing)
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.top, verticalSpacing)
                .padding(.bottom, safeBottom + verticalSpacing * 2)
            }
            .background(ColorPalette.backgroundPrimary.ignoresSafeArea())
            .contentShape(Rectangle())
            .onTapGesture {
                dismissKeyboard()
            }
        }
        .navigationTitle("Report lost item")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .alert(alertTitle, isPresented: $isShowingAlert) {
            Button("OK", role: .cancel) {
                focusedField = nil
            }
        } message: {
            Text(alertMessage)
        }
        .fullScreenCover(isPresented: $isMapPickerPresented) {
            MapPickerScreen(
                initialCoordinate: selectedCoordinate,
                mapCameraPosition: $mapCameraPosition,
                defaultRegion: defaultRegion,
                pinFocusSpan: previewMapSpan
            ) { coordinate in
                applyMapSelection(coordinate)
            }
        }
        .sheet(isPresented: $isShowingCamera) {
            ImagePickerWrapper(sourceType: .camera) { image in
                handleImageSelection(image)
            }
        }
        .sheet(isPresented: $isShowingPhotoPicker) {
            PhotoPickerWrapper { image in
                handleImageSelection(image)
            }
        }
    }
}

// MARK: - View Builders

private extension LostReportFormView {
    enum Field: Hashable {
        case title, description, location, phone
    }
    
    func sectionTitle(_ text: String, fontSize: CGFloat) -> some View {
        Text(text)
            .font(.custom("IBMPlexSans", size: fontSize))
            .foregroundColor(ColorPalette.labelPrimary.opacity(0.85))
            .padding(.horizontal, 4)
    }
    
    func card<Content: View>(cornerRadius: CGFloat, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            content()
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ColorPalette.actionButtonBackground)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
    }
    
    func labelText(_ text: String, fontSize: CGFloat) -> some View {
        Text(text)
            .font(.custom("IBMPlexSans", size: fontSize))
            .foregroundColor(ColorPalette.labelPrimary)
    }
    
    func helperText(_ text: String, fontSize: CGFloat) -> some View {
        Text(text)
            .font(.custom("IBMPlexSans", size: max(fontSize * 0.8, 12)))
            .foregroundColor(ColorPalette.labelPrimary.opacity(0.65))
    }
    
    func textFieldBackground(readOnly: Bool = false) -> some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(
                readOnly
                ? ColorPalette.labelPrimary.opacity(0.08)
                : ColorPalette.backgroundPrimary
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(ColorPalette.labelPrimary.opacity(0.15), lineWidth: 1)
            )
    }
    
    func categoryPicker(labelFontSize: CGFloat, bodyFontSize: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            labelText("Category", fontSize: labelFontSize)
            
            Menu {
                Picker("Category", selection: $selectedCategory) {
                    ForEach(ReportCategory.allCases) { category in
                        Text(category.displayName).tag(Optional(category))
                    }
                }
            } label: {
                HStack {
                    Text(selectedCategory?.displayName ?? "Select Category")
                        .font(.custom("IBMPlexSans", size: bodyFontSize))
                        .foregroundColor(selectedCategory == nil ? ColorPalette.labelPrimary.opacity(0.5) : ColorPalette.labelPrimary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: bodyFontSize, weight: .semibold))
                        .foregroundColor(ColorPalette.labelPrimary.opacity(0.7))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(textFieldBackground())
            }
            .buttonStyle(.plain)
        }
    }
    
    func titleField(labelFontSize: CGFloat, bodyFontSize: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            labelText("Title", fontSize: labelFontSize)
            
            TextField("e.g. Green Notebook", text: $titleText)
                .font(.custom("IBMPlexSans", size: bodyFontSize))
                .foregroundColor(ColorPalette.labelPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(textFieldBackground())
                .focused($focusedField, equals: .title)
                .submitLabel(.return)
                .onSubmit { focusedField = .description }
                .onChange(of: titleText) { newValue in
                    enforceLimit(&titleText, limit: titleLimit)
                }
        }
    }
    
    func descriptionField(labelFontSize: CGFloat, bodyFontSize: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            labelText("Description (optional)", fontSize: labelFontSize)
            
            TextField("Additional details", text: $descriptionText, axis: .vertical)
                .font(.custom("IBMPlexSans", size: bodyFontSize))
                .foregroundColor(ColorPalette.labelPrimary)
                .lineLimit(1...8)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(textFieldBackground())
                .focused($focusedField, equals: .description)
                .submitLabel(.return)
                .onSubmit { focusedField = .location }
                .onChange(of: descriptionText) { _ in
                    enforceLimit(&descriptionText, limit: descriptionLimit)
                }
        }
    }
    
    func imageUploadSection(labelFontSize: CGFloat, bodyFontSize: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            labelText("Image (optional)", fontSize: labelFontSize)
            
            if let uploadedImage = imageUploadService.selectedImage,
               imageUploadService.uploadedImageURL != nil {
                // Show uploaded image preview
                imagePreview(image: uploadedImage, bodyFontSize: bodyFontSize)
            } else if imageUploadService.isUploading {
                // Show upload progress
                uploadProgressView(bodyFontSize: bodyFontSize)
            } else {
                // Show upload button
                uploadButton(bodyFontSize: bodyFontSize)
            }
            
            // Show error message if upload failed
            if let error = imageUploadService.uploadError {
                Text(error)
                    .font(.custom("IBMPlexSans", size: bodyFontSize * 0.85))
                    .foregroundColor(.red)
                    .padding(.top, 4)
            }
        }
    }
    
    func uploadButton(bodyFontSize: CGFloat) -> some View {
        Menu {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button {
                    isShowingCamera = true
                } label: {
                    Label("Take Photo", systemImage: "camera")
                }
            }
            
            Button {
                isShowingPhotoPicker = true
            } label: {
                Label("Choose from Library", systemImage: "photo.on.rectangle")
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "photo.on.rectangle")
                    .font(.system(size: bodyFontSize + 4, weight: .medium))
                
                Text("Add item photo")
                    .font(.custom("IBMPlexSans", size: bodyFontSize))
            }
            .foregroundColor(ColorPalette.labelPrimary.opacity(0.7))
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(ColorPalette.labelPrimary.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [6]))
            )
        }
        .buttonStyle(.plain)
        .onTapGesture {
            dismissKeyboard()
        }
    }
    
    func uploadProgressView(bodyFontSize: CGFloat) -> some View {
        VStack(spacing: 12) {
            HStack {
                ProgressView()
                    .progressViewStyle(.circular)
                
                Text("Uploading image...")
                    .font(.custom("IBMPlexSans", size: bodyFontSize))
                    .foregroundColor(ColorPalette.labelPrimary.opacity(0.7))
            }
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(ColorPalette.labelPrimary.opacity(0.05))
            )
        }
    }
    
    func imagePreview(image: UIImage, bodyFontSize: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 200)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(ColorPalette.labelPrimary.opacity(0.1), lineWidth: 1)
                )
            
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: bodyFontSize))
                
                Text("Image uploaded successfully")
                    .font(.custom("IBMPlexSans", size: bodyFontSize * 0.9))
                    .foregroundColor(ColorPalette.labelPrimary.opacity(0.7))
                
                Spacer()
                
                Button("Remove") {
                    imageUploadService.clearImage()
                }
                .font(.custom("IBMPlexSans", size: bodyFontSize * 0.9))
                .foregroundColor(ColorPalette.witGradient2)
            }
        }
    }
    
    func locationBuildingField(labelFontSize: CGFloat, bodyFontSize: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            labelText("Last known building", fontSize: labelFontSize)
            
            TextField("e.g. Beatty Hall, 410", text: $locationBuilding)
                .font(.custom("IBMPlexSans", size: bodyFontSize))
                .foregroundColor(ColorPalette.labelPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(textFieldBackground())
                .focused($focusedField, equals: .location)
                .submitLabel(.return)
                .onSubmit { focusedField = .phone }
                .onChange(of: locationBuilding) { _ in
                    enforceLimit(&locationBuilding, limit: locationLimit)
                }
        }
    }
    
    func locationPickerMap(labelFontSize: CGFloat, bodyFontSize: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            labelText("Drop a pin (optional)", fontSize: labelFontSize)
            
            Button {
                prepareForMapPickerPresentation()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "map")
                        .font(.system(size: bodyFontSize + 2, weight: .medium))
                        .foregroundColor(ColorPalette.witGradient2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(selectedCoordinate == nil ? "Open map picker" : "Update selected pin")
                            .font(.custom("IBMPlexSans", size: bodyFontSize))
                            .foregroundColor(ColorPalette.labelPrimary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: bodyFontSize, weight: .semibold))
                        .foregroundColor(ColorPalette.labelPrimary.opacity(0.7))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(textFieldBackground())
            }
            .buttonStyle(.plain)
            
            if let coordinate = selectedCoordinate {
                mapPreview(for: coordinate, bodyFontSize: bodyFontSize)
            }
        }
    }
    
    func mapPreview(for coordinate: CLLocationCoordinate2D, bodyFontSize: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Map(position: .constant(.region(previewRegion(for: coordinate))), interactionModes: []) {
                Annotation("", coordinate: coordinate) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.title2)
                        .foregroundStyle(ColorPalette.witGold, ColorPalette.witGradient2)
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                }
            }
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(ColorPalette.labelPrimary.opacity(0.1), lineWidth: 1)
            )
            
            HStack(alignment: .firstTextBaseline) {
                helperText("Preview", fontSize: bodyFontSize)
                
                Spacer()
                
                Button("Remove pin") {
                    clearPinFromForm()
                }
                .font(.custom("IBMPlexSans", size: bodyFontSize * 0.9))
                .foregroundColor(ColorPalette.witGradient2)
            }
        }
    }
    
    func readOnlyField(
        title: String,
        value: String,
        labelFontSize: CGFloat,
        bodyFontSize: CGFloat
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            labelText(title, fontSize: labelFontSize)
            
            Text(value)
                .font(.custom("IBMPlexSans", size: bodyFontSize))
                .foregroundColor(ColorPalette.labelPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(textFieldBackground(readOnly: true))
        }
    }
    
    func phoneField(labelFontSize: CGFloat, bodyFontSize: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            labelText("Phone number", fontSize: labelFontSize)
            
            TextField("Phone number", text: $phoneNumber)
                .font(.custom("IBMPlexSans", size: bodyFontSize))
                .foregroundColor(ColorPalette.labelPrimary)
                .keyboardType(.numberPad)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(textFieldBackground())
                .focused($focusedField, equals: .phone)
                .onChange(of: phoneNumber) { newValue in
                    let digitsOnly = newValue.filter(\.isNumber)
                    if digitsOnly.count > phoneLimit {
                        phoneNumber = String(digitsOnly.prefix(phoneLimit))
                    } else {
                        phoneNumber = digitsOnly
                    }
                }
            
        }
    }
    
    var submitButtonLabel: some View {
        HStack(spacing: 10) {
            if isSubmitting {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: ColorPalette.witRichBlack))
                    .scaleEffect(0.9)
            }
            
            Text(isSubmitting ? "Submitting..." : "Submit report")
                .font(.custom("IBMPlexSans", size: 18))
                .foregroundColor(ColorPalette.witRichBlack)
        }
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [ColorPalette.witGold, ColorPalette.witGradient2],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Helpers

private extension LostReportFormView {
    var trimmedTitle: String {
        titleText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var trimmedLocation: String {
        locationBuilding.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var trimmedDescription: String? {
        let trimmed = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
    
    var isFormSubmittable: Bool {
        selectedCategory != nil &&
        !trimmedTitle.isEmpty &&
        !trimmedLocation.isEmpty &&
        phoneNumber.count == phoneLimit
    }
    
    var selectedReportCoordinates: ReportCoordinates? {
        guard let coordinate = selectedCoordinate else { return nil }
        return ReportCoordinates(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
    
    var defaultRegion: MKCoordinateRegion {
        MKCoordinateRegion(center: defaultCoordinate, span: defaultMapSpan)
    }
    
    func previewRegion(for coordinate: CLLocationCoordinate2D) -> MKCoordinateRegion {
        MKCoordinateRegion(center: coordinate, span: previewMapSpan)
    }
    
    func applyMapSelection(_ coordinate: CLLocationCoordinate2D?) {
        withAnimation(.easeInOut) {
            selectedCoordinate = coordinate
            if let coordinate = coordinate {
                mapCameraPosition = .region(previewRegion(for: coordinate))
            } else {
                mapCameraPosition = .region(defaultRegion)
            }
        }
    }
    
    func prepareForMapPickerPresentation() {
        if selectedCoordinate == nil {
            mapCameraPosition = .region(defaultRegion)
        }
        dismissKeyboard()
        isMapPickerPresented = true
    }
    
    func clearPinFromForm() {
        applyMapSelection(nil)
    }
    
    func enforceLimit(_ text: inout String, limit: Int) {
        if text.count > limit {
            text = String(text.prefix(limit))
        }
    }
    
    func dismissKeyboard() {
        focusedField = nil
    }
    
    func handleImageSelection(_ image: UIImage) {
        Task {
            let url = await imageUploadService.uploadImage(image)
            if url == nil {
                // Error is already set in imageUploadService.uploadError
                alertTitle = "Upload Failed"
                alertMessage = imageUploadService.uploadError ?? "Failed to upload image. Please try again."
                isShowingAlert = true
            }
        }
    }
    
    /// Converts a Report model to a Firestore-compatible dictionary
    func convertReportToFirestoreData(_ report: Report) -> [String: Any] {
        var data: [String: Any] = [
            "id": report.id.uuidString,
            "category": report.category.rawValue,
            "createdByName": report.createdByName,
            "createdByEmail": report.createdByEmail,
            "createdByPhone": report.createdByPhone,
            "createdAt": Timestamp(date: report.createdAt),
            "title": report.title,
            "locationBuilding": report.locationBuilding,
            "status": report.status.rawValue,
            "type": report.type.rawValue
        ]
        
        // Add optional description
        if let description = report.description {
            data["description"] = description
        } else {
            data["description"] = NSNull()
        }
        
        // Add optional imageUrl
        if let imageUrl = report.imageUrl {
            data["imageUrl"] = imageUrl.absoluteString
        } else {
            data["imageUrl"] = NSNull()
        }
        
        // Add optional locationCoordinates as GeoPoint
        if let coordinates = report.locationCoordinates {
            data["locationCoordinates"] = GeoPoint(
                latitude: coordinates.latitude,
                longitude: coordinates.longitude
            )
        } else {
            data["locationCoordinates"] = NSNull()
        }
        
        // Add optional reviewedAt
        if let reviewedAt = report.reviewedAt {
            data["reviewedAt"] = Timestamp(date: reviewedAt)
        } else {
            data["reviewedAt"] = NSNull()
        }
        
        // Add optional reviewedBy
        if let reviewedBy = report.reviewedBy {
            data["reviewedBy"] = reviewedBy
        } else {
            data["reviewedBy"] = NSNull()
        }
        
        return data
    }
    
    /// Submits the report to Firestore
    func submitToFirestore(_ report: Report) async throws {
        let db = Firestore.firestore()
        let reportData = convertReportToFirestoreData(report)
        
        // Use the report's UUID as the document ID
        let documentRef = db.collection("reports").document(report.id.uuidString)
        
        try await documentRef.setData(reportData)
        
        #if DEBUG
        print("Successfully submitted report to Firestore with ID: \(report.id.uuidString)")
        print("Report data: \(reportData)")
        #endif
    }
    
    func handleSubmit() {
        guard let category = selectedCategory else {
            alertTitle = "Missing information"
            alertMessage = "Please select a category for your item."
            isShowingAlert = true
            return
        }
        
        guard isFormSubmittable else {
            alertTitle = "Missing information"
            alertMessage = "Please complete the required fields and ensure your phone number includes 10 digits."
            isShowingAlert = true
            return
        }
        
        // Dismiss keyboard before submission
        focusedField = nil
        
        // Create the report with all required fields
        let newReport = Report(
            id: UUID(),
            category: category,
            createdByName: currentUserName,
            createdByEmail: currentUserEmail,
            createdByPhone: phoneNumber,
            createdAt: Date(),
            description: trimmedDescription,
            title: trimmedTitle,
            imageUrl: imageUploadService.uploadedImageURL,
            locationBuilding: trimmedLocation,
            locationCoordinates: selectedReportCoordinates,
            reviewedAt: nil,
            reviewedBy: nil,
            status: .pending,
            type: .lost
        )
        
        // Store draft for potential retry
        draftReport = newReport
        
        // Submit to Firestore
        Task {
            isSubmitting = true
            
            do {
                try await submitToFirestore(newReport)
                
                // Success: show success message and navigate back
                await MainActor.run {
                    isSubmitting = false
                    alertTitle = "Success!"
                    alertMessage = "Your report has been submitted for approval."
                    isShowingAlert = true
                }
                
                // Wait a moment for the user to see the alert, then dismiss
                try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
                await MainActor.run {
                    dismiss()
                }
                
            } catch {
                // Error: show error alert with option to retry
                await MainActor.run {
                    isSubmitting = false
                    alertTitle = "Submission Failed"
                    alertMessage = "Failed to submit your report: \(error.localizedDescription). Please try again."
                    isShowingAlert = true
                }
                
                #if DEBUG
                print("Error submitting report to Firestore: \(error)")
                print("Error details: \(error)")
                #endif
            }
        }
    }
}

// MARK: - Map Picker Screen

private struct MapPickerScreen: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var mapCameraPosition: MapCameraPosition
    @State private var workingCoordinate: CLLocationCoordinate2D?
    
    let defaultRegion: MKCoordinateRegion
    let pinFocusSpan: MKCoordinateSpan
    let onSelectionChange: (CLLocationCoordinate2D?) -> Void
    
    init(
        initialCoordinate: CLLocationCoordinate2D?,
        mapCameraPosition: Binding<MapCameraPosition>,
        defaultRegion: MKCoordinateRegion,
        pinFocusSpan: MKCoordinateSpan,
        onSelectionChange: @escaping (CLLocationCoordinate2D?) -> Void
    ) {
        self._mapCameraPosition = mapCameraPosition
        self.defaultRegion = defaultRegion
        self.pinFocusSpan = pinFocusSpan
        self.onSelectionChange = onSelectionChange
        _workingCoordinate = State(initialValue: initialCoordinate)
    }
    
    var body: some View {
        NavigationStack {
            MapReader { proxy in
                GeometryReader { geometry in
                    ZStack {
                        Map(position: $mapCameraPosition, interactionModes: .all) {
                            if let coordinate = workingCoordinate {
                                Annotation("", coordinate: coordinate) {
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.title)
                                        .foregroundStyle(ColorPalette.witGold, ColorPalette.witGradient2)
                                        .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 4)
                                }
                            }
                        }
                        .ignoresSafeArea()
                        
                        // Crosshair overlay (always visible, centered)
                        crosshairView
                        
                        Spacer()
                        
                        // Floating buttons at bottom
                        VStack {
                            Spacer()
                            
                            VStack(spacing: 12) {
                                // Drop/Replace Pin button
                                Button {
                                    dropPinAtCrosshair(proxy: proxy, geometry: geometry)
                                } label: {
                                    Text(workingCoordinate == nil ? "Drop Pin" : "Replace Pin")
                                        .font(.custom("IBMPlexSans", size: 16).weight(.semibold))
                                        .foregroundColor(ColorPalette.witRichBlack)
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 12)
                                        .background(
                                            Capsule()
                                                .fill(ColorPalette.witGold)
                                        )
                                        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 4)
                                }
                                
                                // Clear Pin / Reset button
                                Button {
                                    withAnimation(.easeInOut) {
                                        workingCoordinate = nil
                                        mapCameraPosition = .region(defaultRegion)
                                    }
                                } label: {
                                    Text(workingCoordinate == nil ? "Reset" : "Clear Pin")
                                        .font(.custom("IBMPlexSans", size: 16))
                                        .foregroundColor(ColorPalette.labelPrimary)
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 12)
                                        .background(
                                            Capsule()
                                                .fill(ColorPalette.backgroundPrimary.opacity(0.95))
                                        )
                                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)
                                }
                            }
                            .padding(.bottom, geometry.size.height * 0.1)
                        }
                    }
                }
            }
            .ignoresSafeArea()
            .navigationTitle("Drop a pin")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.custom("IBMPlexSans", size: 16))
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        onSelectionChange(workingCoordinate)
                        dismiss()
                    }
                    .font(.custom("IBMPlexSans", size: 16).weight(.semibold))
                }
            }
        }
    }
    
    private func dropPinAtCrosshair(proxy: MapProxy, geometry: GeometryProxy) {
        // Get the center point of the GeometryReader's frame in global coordinates
        // This accounts for the Map's ignoresSafeArea() behavior
        let frame = geometry.frame(in: .global)
        let centerPoint = CGPoint(
            x: frame.midX,
            y: frame.midY
        )
        
        // Convert the center point to map coordinates using global coordinate space
        guard let coordinate = proxy.convert(centerPoint, from: .global) else { return }
        
        withAnimation(.easeInOut) {
            workingCoordinate = coordinate
        }
    }
    
    private var instructionCard: some View {
        Text("Move the map to position the crosshair, then tap Drop Pin")
            .font(.custom("IBMPlexSans", size: 15))
            .foregroundColor(ColorPalette.labelPrimary)
            .multilineTextAlignment(.center)
            .padding(12)
            .background(ColorPalette.backgroundPrimary.opacity(0.95))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
    }
    
    private var crosshairView: some View {
        ZStack {
            // Vertical line
            Rectangle()
                .fill(Color.black)
                .frame(width: 2, height: 30)
            
            // Horizontal line
            Rectangle()
                .fill(Color.black)
                .frame(width: 30, height: 2)
        }
    }
    
}

#Preview {
    NavigationStack {
        LostReportFormView(
            currentUserName: "Jordan Clark",
            currentUserEmail: "jclark@wit.edu"
        )
    }
}

