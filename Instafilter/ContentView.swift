//
//  ContentView.swift
//  Instafilter
//
//  Created by Dominique Strachan on 12/22/23.
//

import CoreImage
import CoreImage.CIFilterBuiltins
// for photos picker
import PhotosUI
// for review
import StoreKit
import SwiftUI

struct ContentView: View {
    @State private var processedImage: Image?
    @State private var filterIntensity = 0.5
    @State private var filterRadius = 3.0
    @State private var filterScale = 5.0
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showingFilters = false
    
    @AppStorage("filterCount") var filterCount = 0
    @Environment(\.requestReview) var requestReview
    
    @State private var currentFilter: CIFilter = CIFilter.sepiaTone()
    let context = CIContext()
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                
                PhotosPicker(selection: $selectedPhoto) {
                    if let processedImage {
                        processedImage
                            .resizable()
                            .scaledToFit()
                    } else {
                        ContentUnavailableView("No picture", systemImage: "photo.badge.plus", description: Text("Tap to import photo"))
                    }
                }
                .onChange(of: selectedPhoto, loadImage)
               // .buttonStyle(.plain)
                
                Spacer()
                
//                HStack {
//                    Text("Intensity")
//                    Slider(value: $filterIntensity, in: 0...200)
//                        .onChange(of: filterIntensity, applyProcessing)
//                }
//                    .disabled(processedImage == nil)
                
                VStack {
                    if currentFilter.inputKeys.contains(kCIInputIntensityKey) {
                        HStack {
                            Text("Intensity")
                            Slider(value: $filterIntensity)
                                .onChange(of: filterIntensity, applyProcessing)
                        }
                        .disabled(processedImage == nil)
                    }
                    
                    if currentFilter.inputKeys.contains(kCIInputRadiusKey) {
                        HStack {
                            Text("Radius")
                            Slider(value: $filterRadius, in: 0...200)
                                .onChange(of: filterRadius, applyProcessing)
                        }
                        .disabled(processedImage == nil)
                    }
                    
                    if currentFilter.inputKeys.contains(kCIInputScaleKey) {
                        HStack {
                            Text("Scale")
                            Slider(value: $filterScale, in: 0...10)
                                .onChange(of: filterIntensity, applyProcessing)
                        }
                        .disabled(processedImage == nil)
                    }

                }
                .padding(.vertical)
                
                HStack {
                    Button("Change Filter", action: changeFilter)
                        .disabled(processedImage == nil)
                    
                    Spacer()
                    
                    if let processedImage {
                        ShareLink(item: processedImage, preview: SharePreview("Instafilter image", image: processedImage)) {
                            Label("Share Picture", systemImage: "square.and.arrow.up")
                        }
                    }
                }
            }
            .padding([.horizontal, .bottom])
            .navigationTitle("Instafilter")
            .confirmationDialog("Select a filter", isPresented: $showingFilters) {
                Button("Bloom") { setFilter(CIFilter.bloom()) }
                Button("Noir") { setFilter(CIFilter.sepiaTone()) }
                Button("Crystallize") { setFilter(CIFilter.photoEffectNoir() )}
                Button("Edges") { setFilter(CIFilter.edges()) }
                // app will crash since Gaussian Blur has radius effect not intensity from slider
                Button("Gaussian Blur") { setFilter(CIFilter.gaussianBlur()) }
                Button("Pixellate") { setFilter(CIFilter.pixellate()) }
                Button("Sepia Tone") { setFilter(CIFilter.sepiaTone()) }
                Button("Unsharp Mask") { setFilter(CIFilter.unsharpMask()) }
                Button("Vignette") { setFilter(CIFilter.vignette()) }
                Button("Pointillize") { setFilter(CIFilter.pointillize()) }
                Button("Cancel", role: .cancel) { }
            }
        }
    }
    
    func changeFilter() {
        showingFilters = true
    }
    
    func loadImage() {
        Task {
            guard let imageData = try await selectedPhoto?.loadTransferable(type: Data.self) else { return }
            guard let inputImage = UIImage(data: imageData) else { return }
            
            // safe way of applying filter to selected image
            // for faster run time applying different filters can store result of beginImage into a property
            let beginImage = CIImage(image: inputImage)
            currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
            applyProcessing()
        }
    }
    
    // lot of different kCIInputKeys
    func applyProcessing() {
        let inputKeys = currentFilter.inputKeys
        
        if inputKeys.contains(kCIInputIntensityKey) { currentFilter.setValue(filterIntensity, forKey: kCIInputIntensityKey) }
        if inputKeys.contains(kCIInputRadiusKey) { currentFilter.setValue(filterRadius, forKey: kCIInputRadiusKey) }
        if inputKeys.contains(kCIInputScaleKey) { currentFilter.setValue(filterScale, forKey: kCIInputScaleKey) }
        
//        if inputKeys.contains(kCIInputIntensityKey) { currentFilter.setValue(filterIntensity, forKey: kCIInputIntensityKey) }
//        if inputKeys.contains(kCIInputRadiusKey) { currentFilter.setValue(filterIntensity * 200, forKey: kCIInputRadiusKey) }
//        if inputKeys.contains(kCIInputScaleKey) { currentFilter.setValue(filterIntensity * 10, forKey: kCIInputScaleKey) }
 
        
        // currentFilter.setValue(filterIntensity, forKey: kCIInputIntensityKey)
        
        // float for core image
       // currentFilter.intensity = Float(filterIntensity)
        
        guard let outputImage = currentFilter.outputImage else { return }
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else { return }
                
        let uiImage = UIImage(cgImage: cgImage)
        processedImage = Image(uiImage: uiImage)
    }
    
    @MainActor func setFilter(_ filter: CIFilter) {
        currentFilter = filter
        loadImage()
        
        filterCount += 1
        
        if filterCount >= 20 {
            requestReview()
        }
    }

}


#Preview {
    ContentView()
}
