//
//  GPU.swift
//  MetalED
//
//  Created by Henrik Akesson on 04/06/2016.
//  Copyright © 2016 Henrik Akesson. All rights reserved.
//

import MetalKit

/* Represents the single GPU of the phone (will not use multi-GPU stuff) */
final class GPU {
    
    fileprivate static var compiledFunctions = [String:MTLFunction]()
    
    static let device = MTLCreateSystemDefaultDevice()!
    static let library = device.newDefaultLibrary()!
    static let commandQueue = device.makeCommandQueue()
    
    static func computePipelineStateFor(_ function: String) -> MTLComputePipelineState {
        let computeFunction = getFunction(function)
        var computePipelineState: MTLComputePipelineState
        do {
            try computePipelineState = device.makeComputePipelineState(function: computeFunction)
        } catch {
            fatalError("Error occurred when compiling compute pipeline: \(error)")
        }
        return computePipelineState
    }
    
    static func renderPipelineStateFor(_ name: String, vertexFunction: String, fragmentFunction: String) -> MTLRenderPipelineState {
        // create a pipeline state descriptor for a vertex/fragment shader combo
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.label = name
        descriptor.vertexFunction = getFunction(vertexFunction)
        descriptor.fragmentFunction = getFunction(fragmentFunction)
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        descriptor.vertexDescriptor = FullScreenVertexes.descriptor
        
        // create the actual pipeline state
        var info:MTLRenderPipelineReflection? = nil
        do {
            let pipelineState = try device.makeRenderPipelineState(descriptor: descriptor, options: MTLPipelineOption.bufferTypeInfo, reflection: &info)
            return pipelineState
            
        } catch let pipelineError as NSError {
            fatalError("Failed to create pipeline state for shaders \(vertexFunction):\(fragmentFunction) error \(pipelineError)")
        }
    }
    
    static func getFunction(_ name: String) -> MTLFunction {
        return compiledFunctions.lookupOrAdd(name) { newFunction(name) }
    }
    
    fileprivate static func newFunction(_ name: String) -> MTLFunction {
        guard let function = library.makeFunction(name: name) else {
            fatalError("Failed to retrieve kernel function \(name) from library")
        }
        return function;
    }
    
    static func newSamplerState(_ descriptor: MTLSamplerDescriptor) -> MTLSamplerState {
        return device.makeSamplerState(descriptor: descriptor)
    }
 
    static func newTexture(width: Int, height: Int) -> MTLTexture {
        let desc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.bgra8Unorm, width: width, height: height, mipmapped: false)
        return device.makeTexture(descriptor: desc)
    }
    
    static func newBuffer(_ data:[Float]) -> MTLBuffer {
        // set up vertex buffer
        let dataSize = data.count * MemoryLayout.size(ofValue: data[0]) // 1
        
        let options:MTLResourceOptions = MTLResourceOptions.storageModeShared.union([])
        return device.makeBuffer(bytes: data, length: dataSize, options: options)
    }
    
    static func commandBuffer() -> MTLCommandBuffer {
        return commandQueue.makeCommandBuffer()
    }
}
