#pragma once
#include "Request.h"
#include "ProviderTypes.h"
#include <memory>
namespace MusicProviders {
// Composition owner for multi-step operations; every child belongs to the handle.
template<class T> struct Operation {
    QPointer<Request> handle, child;
    Completion<T> completion;
    bool finished = false;
    void finish(Result<T> result) {
        if (!handle || finished) return;
        finished = true;
        completion(std::move(result));
    }
    static std::shared_ptr<Operation> create(QObject *context, Completion<T> done) {
        auto op = std::make_shared<Operation>();
        op->handle = new Request(context); op->completion = std::move(done);
        op->handle->setCancelHandler([op] {
            if (op->finished) return;
            op->finish(Error{ErrorCode::Cancelled, QStringLiteral("Request cancelled.")});
            if (op->child) op->child->cancel();
        });
        return op;
    }
};
}
