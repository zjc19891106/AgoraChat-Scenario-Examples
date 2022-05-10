package io.agora.e3kitdemo.utils

import io.agora.ValueCallBack

abstract class ResultCallBack<T> : ValueCallBack<T> {
    /**
     * For situations where only error code is returned
     * @param error
     */
    fun onError(error: Int) {
        onError(error, null)
    }
}